//
//  HTYGLKVC.m
//  HTY360Player
//
//  Created by 张乐昌 on 2018/3/27.
//  Copyright © 2018年 张乐昌. All rights reserved.
//

#import "PanoramaVC.h"
#import "GLProgram.h"
#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>

#define ES_PI  (3.14159265f)
#define ROLL_CORRECTION      ES_PI/2.0
#define FramesPerSecond      30
#define SphereSliceNum       200
#define SphereRadius         1
#define SphereScale          100
#define ANIMATIONDURATION    1  //动画持续时长
#define FINGER_SENSITIVE_Y     3
#define FINGER_SENSITIVE_X     3

// For digital component video the color format YCbCr is used.
// ITU-R BT.709, which is the standard for HDTV.
// http://www.equasys.de/colorconversion.html
const GLfloat kColorConversion709[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};

// Uniform index.
enum {
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_Y,
    UNIFORM_UV,
    UNIFORM_COLOR_CONVERSION_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];
typedef enum INITOrientation
{
    INITOrientation_Unknown,
    INITOrientation_Portrait,
    INITOrientation_PortraitUpsideDown,
    INITOrientation_LandscapeLeft,
    INITOrientation_LandscapeRight,
    INITOrientation_FaceUp,
    INITOrientation_FaceDown
} INITOrientation;
@interface PanoramaVC ()
{
     CGFloat n_overtrue; //同overture
     CGFloat n_perspectofs; //同perspectoffset
     CGFloat n_overtrue_rate;
     CGFloat n_finger_rate;
     CGFloat n_perspectofs_rate;
     CGFloat n_fingerX;
     CGFloat n_fingerY;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLProgram *program;
@property (strong, nonatomic) NSMutableArray *currentTouches;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (assign, nonatomic) CGFloat overture;
@property (assign, nonatomic) CGFloat fingerRotationX;
@property (assign, nonatomic) CGFloat fingerRotationY;
@property (assign, nonatomic) CGFloat fingerRotationZ;//虚拟
@property (assign, nonatomic) int numIndices;
@property (assign, nonatomic) CVOpenGLESTextureRef lumaTexture;
@property (assign, nonatomic) CVOpenGLESTextureRef chromaTexture;
@property (assign, nonatomic) CVOpenGLESTextureCacheRef videoTextureCache;
@property (assign, nonatomic) GLKMatrix4 modelViewProjectionMatrix;
@property (assign, nonatomic) GLuint vertexIndicesBufferID;
@property (assign, nonatomic) GLuint vertexBufferID;
@property (assign, nonatomic) GLuint vertexTexCoordID;
@property (assign, nonatomic) GLuint vertexTexCoordAttributeIndex;
@property (strong, nonatomic) UIPinchGestureRecognizer *pinchRecognizer;
@property (assign, nonatomic, readwrite)  BOOL isUsingMotion;
@property (assign, nonatomic,  readonly)  CGFloat defaultOverture;
@property (assign, nonatomic,  readonly)  CGFloat minimumOverture;
@property (assign, nonatomic,  readonly)  CGFloat maximumOverture;
@property (assign, nonatomic,  readwrite) CGFloat scale;
@property (assign, nonatomic,  readonly)  CGFloat offset;
@property (assign, nonatomic,  readonly)  BOOL isActualRefresh;//是否为实时刷新
@property (assign, nonatomic,  readonly)  CGFloat camRotX;
@property (assign, nonatomic,  readonly)  CGFloat objRotX;
@property (nonatomic, strong, readwrite)GLKBaseEffect *effect;
@property (nonatomic, strong)GLKTextureInfo *textureInfo;
@property (nonatomic, strong)NSDictionary   *options;
@property (nonatomic, assign)INITOrientation originalOrientation;
@property (nonatomic, assign)INITOrientation nowOrientation;
@property (nonatomic, assign)CGFloat oriOffsetX;             //横竖屏偏移量
@property (nonatomic, assign)CGFloat perspectOffset;         //视角offset
@property (nonatomic, assign)CGFloat perspectOffsetX;        //区分小行星,鱼眼等的RotX
@property (nonatomic, assign)CVPixelBufferRef ioBufferRef;   //存留数据


- (void)setupGL;
- (void)tearDownGL;
- (void)buildProgram;

@end

@implementation PanoramaVC

-(void)setPerspectiveMode:(ZLCPanoPerspectMode)perspectiveMode
{
    _perspectiveMode = perspectiveMode;
     self.overture = self.defaultOverture;
    [self updateOverture];
    [self updateFingerParameters];
}

-(void)setGyroMotioning:(BOOL)gyroMotioning
{
    _gyroMotioning = gyroMotioning;
    if (gyroMotioning) {
        [self startDeviceMotion];
    }else{
        [self stopDeviceMotion];
    }
}


-(CGFloat)defaultOverture
{
    CGFloat defOverture = 80;
    if (_srcType == ZLCPanoSRCTypeStream) {
        switch (_perspectiveMode)
        {
            case ZLCPanoPerspectModeNormal:
                defOverture = 35;
                break;
            case ZLCPanoPerspectModeLittlePlanet:
                defOverture = 130;
                break;
            case ZLCPanoPerspectModeFisheye:
                defOverture = 80;
            default:
                break;
        }
    }else if(_srcType == ZLCPanoSRCTypePicture){
        switch (_perspectiveMode)
        {
            case ZLCPanoPerspectModeNormal:
                defOverture = 65;
                break;
            case ZLCPanoPerspectModeLittlePlanet:
                defOverture = 150;
                break;
            case ZLCPanoPerspectModeFisheye:
                defOverture = 120;
                break;
            default:
                break;
        }
    }
    return defOverture;
}

-(CGFloat)minimumOverture
{
    CGFloat minOverture = 60;
    if (_srcType == ZLCPanoSRCTypeStream) {
        switch (_perspectiveMode) {
            case ZLCPanoPerspectModeNormal:
                minOverture = 30;
                break;
            case ZLCPanoPerspectModeLittlePlanet:
                minOverture = 90;
                break;
            case ZLCPanoPerspectModeFisheye:
                minOverture = 40;
                break;
            default:
                break;
        }
    }else if(_srcType == ZLCPanoSRCTypePicture)
    {
        switch (_perspectiveMode) {
            case ZLCPanoPerspectModeNormal:
                minOverture = 50;
                break;
            case ZLCPanoPerspectModeLittlePlanet:
                minOverture = 110;
                break;
            case ZLCPanoPerspectModeFisheye:
                minOverture = 70;
                break;
            default:
                break;
        }
    }
    return minOverture;
}

-(CGFloat)maximumOverture
{
    CGFloat maxOverture = 100;
    if (_srcType == ZLCPanoSRCTypeStream) {
        switch (_perspectiveMode) {
            case ZLCPanoPerspectModeNormal:
                maxOverture = 60;
                break;
            case ZLCPanoPerspectModeLittlePlanet:
                maxOverture = 155;
                break;
            case ZLCPanoPerspectModeFisheye:
                maxOverture = 140;
                break;
            default:
                break;
        }
    }else if(_srcType == ZLCPanoSRCTypePicture)
    {
        switch (_perspectiveMode) {
            case ZLCPanoPerspectModeNormal:
                maxOverture = 80;
                break;
            case ZLCPanoPerspectModeLittlePlanet:
                maxOverture = 160;
                break;
            case ZLCPanoPerspectModeFisheye:
                maxOverture = 150;
                break;
            default:
                break;
        }
    }
    return maxOverture;
}

-(CGFloat)scale
{
    CGFloat sle = SphereScale;
    switch (_perspectiveMode) {
        case ZLCPanoPerspectModeNormal:
            sle = SphereScale;
            break;
        case ZLCPanoPerspectModeLittlePlanet:
            sle = SphereScale*3;
            break;
        case ZLCPanoPerspectModeFisheye:
            sle = 0.13;
            break;
        default:
            break;
    }
    return sle;
}

#pragma mark 手势功能offset

#pragma mark 陀螺仪功能offset
-(CGFloat)offset
{
    CGFloat ofs = 0;
    switch (_perspectiveMode) {
        case ZLCPanoPerspectModeNormal:
            ofs = 0;
            break;
        case ZLCPanoPerspectModeLittlePlanet:
            ofs = 0;
            break;
        case ZLCPanoPerspectModeFisheye:
            ofs = 0;
            break;
        default:
            break;
    }
    return ofs;
}

-(CGFloat)perspectOffset
{
    float rox = 0;
        switch (_perspectiveMode) {
            case ZLCPanoPerspectModeNormal:
                rox = 0;
                break;
            case ZLCPanoPerspectModeFisheye:
                rox = 0;
                break;
            case ZLCPanoPerspectModeLittlePlanet:
                rox = M_PI_2;
                break;
            default:
                break;
        }
    return rox;
}

-(CGFloat)camRotX
{
    CGFloat x = 0;
    switch (_srcType) {
        case ZLCPanoSRCTypePicture:
            x = 1.0f;
            break;
        case ZLCPanoSRCTypeStream:
            x = 1.0f;
            break;
        default:
            break;
    }
    return x;
}

-(CGFloat)objRotX
{
    CGFloat x = 0;
    switch (_srcType) {
        case ZLCPanoSRCTypePicture:
            x = ES_PI;
            break;
        case ZLCPanoSRCTypeStream:
            x = ROLL_CORRECTION;
            break;
        default:
            break;
    }
    return x;
}

-(CGFloat)perspectOffsetX
{
    CGFloat perspectX = 0;
    switch (_perspectiveMode) {
        case ZLCPanoPerspectModeNormal:
            perspectX = 0;
            break;
        case ZLCPanoPerspectModeFisheye:
            perspectX = 0;
            break;
        case ZLCPanoPerspectModeLittlePlanet:
            perspectX = M_PI;
            break;
        default:
            break;
    }
    return perspectX;
}

-(CGFloat)limitMaxValue:(CGFloat)maxValue minValue:(CGFloat)minValue limittedValue:(CGFloat)targetValue
{
    if (targetValue > maxValue) {
        targetValue = maxValue;
    }
    if (targetValue < minValue) {
        targetValue = minValue;
    }
    return targetValue;
}

-(CGFloat)fingerRotationX
{
    CGFloat maxValue = 0;
    CGFloat minValue = 0;
    switch (_perspectiveMode) {
        case ZLCPanoPerspectModeNormal:
        case ZLCPanoPerspectModeFisheye:
        {
            maxValue = M_PI_2;
            minValue = -M_PI_2;
        }
            break;
        case ZLCPanoPerspectModeLittlePlanet:
        {
            maxValue = 0;
            minValue = -M_PI;
        }
            break;
        default:
            break;
    }
    _fingerRotationX = [self limitMaxValue:maxValue minValue:minValue limittedValue:_fingerRotationX];
    return _fingerRotationX;
}

-(CMMotionManager *)motionManager
{
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
        _motionManager.gyroUpdateInterval = 1.0f / 60;
        _motionManager.showsDeviceMovementDisplay = YES;
        [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
    }
    return _motionManager;
}

-(NSDictionary *)options
{
    if (!_options) {
        _options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], GLKTextureLoaderOriginBottomLeft, nil];
    }
    return _options;
}

-(GLKBaseEffect *)effect
{
    if (!_effect) {
        _effect = [[GLKBaseEffect alloc] init];
    }
    return _effect;
}

-(BOOL)isActualRefresh
{
    return (_srcType == ZLCPanoSRCTypeStream);
}

-(void)setLoadImage:(UIImage *)loadImage
{
    _loadImage = loadImage;
    [self cleanUpTextures];
    UIImage *image = [self rotateImage:loadImage degree:M_PI];
    if (image) {
        self.textureInfo = [GLKTextureLoader textureWithCGImage:image.CGImage options:self.options error:nil];
        self.effect. texture2d0.enabled = GL_TRUE;
        self.effect.texture2d0.name = self.textureInfo.name;
    }
}

-(UIImage *)rotateImage:(UIImage *)image degree:(CGFloat)degree
{
   long double rotate = degree;
   CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
   float translateX = -rect.size.width;
   float translateY = -rect.size.height;
   float scaleX = 1.0;
   float scaleY = 1.0;
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    return newPic;
}

- (instancetype)initWithSrcType:(ZLCPanoSRCType)srcType orientation:(UIDeviceOrientation)orientation
{
    self = [[PanoramaVC alloc]initWithSrcType:srcType];
    if (self) {
        _originalOrientation = (INITOrientation)orientation;
    }
    return self;
}


- (instancetype)initWithSrcType:(ZLCPanoSRCType)srcType
{
    self = [super init];
    if (self) {
        _perspectiveMode = ZLCPanoPerspectModeNormal;
        _srcType = srcType;
        _isSupportAnimate = YES;  //默认支持动画
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        _perspectiveMode = ZLCPanoPerspectModeNormal;
        _srcType         = ZLCPanoSRCTypePicture;
        _loadImage       = image;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context)
    {
        NSLog(@"Failed to create ES context");
    }
    [self initGlobalParameter];
    [self addglkView];
    [self setupGL];
    [self addGesture];
    [self InitOriRotXYZ];
}

-(void)initGlobalParameter
{
     n_overtrue    = 0; //同overture
     n_perspectofs = 0; //同perspectoffset
     n_overtrue_rate     = 30.f/10.f;
     n_finger_rate       = 30.f/2.5f;
     n_perspectofs_rate  = 30.f/10.f;
     n_fingerX           = 0;
     n_fingerY           = 0;
}

- (void)InitOriRotXYZ
{
    switch ((INITOrientation)_originalOrientation) {
        case INITOrientation_Unknown:
        case INITOrientation_PortraitUpsideDown:
        case INITOrientation_LandscapeRight:
        case INITOrientation_FaceUp:
        case INITOrientation_FaceDown:
            break;
        case INITOrientation_Portrait:
            _oriOffsetX = M_PI_2;
            break;
        case INITOrientation_LandscapeLeft:
            _oriOffsetX = 0;
            break;
        default:
            break;
    }
    [self setOriginalOrientation:(INITOrientation)_originalOrientation];
    [self setNowOrientation:(INITOrientation)_originalOrientation];
}


- (void)rotateTo: (UIDeviceOrientation)orientation
{
    [self setNowOrientation:(INITOrientation)orientation];
}

-(void)addglkView
{
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    switch (_srcType) {
        case ZLCPanoSRCTypeStream:
            view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
            view.contentScaleFactor = [UIScreen mainScreen].scale;
            break;
        case ZLCPanoSRCTypePicture:
            /// 设置颜色格式和深度格式
            view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
            view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        default:
            break;
    }
    self.preferredFramesPerSecond = FramesPerSecond;
    self.overture = self.defaultOverture;
}


- (void)drawTexture:(UIImage *)image
{
    [self setLoadImage:image];
}
#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
//    NSLog(@"%s +======+ %@",__func__,[NSThread currentThread]);
    if (_srcType == ZLCPanoSRCTypePicture) {  //图片渲染
        //    *清除颜色缓冲区内容时候: 使用蓝色填充
//        glClearColor(0.3f, 0.6f, 1.0f, 1.0f);
        //    *清除颜色缓冲区内容时候: 使用黑色色填充
        glClearColor(0, 0, 0, 1.0f);
        //    *清除颜色缓冲区与深度缓冲区内容
        glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
        [self.effect prepareToDraw];
        glDrawElements(GL_TRIANGLES, self.numIndices, GL_UNSIGNED_SHORT, 0);
    }else if(_srcType == ZLCPanoSRCTypeStream) //视频流渲染
    {
        CVPixelBufferRef pixelBuffer = _ioBufferRef;
        CVReturn err;
        if (pixelBuffer != nil) {
            GLsizei textureWidth  = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
            GLsizei textureHeight = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);
//            NSLog(@"resolution = %d*%d",textureWidth,textureHeight);
            if (!self.videoTextureCache) {
                NSLog(@"No video texture cache");
                return;
            }
            [self cleanUpTextures];
            // Y-plane
            glActiveTexture(GL_TEXTURE0);
            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                               self.videoTextureCache,
                                                               pixelBuffer,
                                                               NULL,
                                                               GL_TEXTURE_2D,
                                                               GL_RED_EXT,
                                                               textureWidth,
                                                               textureHeight,
                                                               GL_RED_EXT,
                                                               GL_UNSIGNED_BYTE,
                                                               0,
                                                               &_lumaTexture);
            if (err) {
                NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture), CVOpenGLESTextureGetName(self.lumaTexture));
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            // UV-plane.
            glActiveTexture(GL_TEXTURE1);
            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                               self.videoTextureCache,
                                                               pixelBuffer,
                                                               NULL,
                                                               GL_TEXTURE_2D,
                                                               GL_RG_EXT,
                                                               textureWidth/2,
                                                               textureHeight/2,
                                                               GL_RG_EXT,
                                                               GL_UNSIGNED_BYTE,
                                                               1,
                                                               &_chromaTexture);
            if (err) {
                NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture), CVOpenGLESTextureGetName(self.chromaTexture));
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            //        CVPixelBufferRelease(pixelBuffer);
            //        CFRelease(pixelBuffer);
        }
        
        glClear(GL_COLOR_BUFFER_BIT);
        glDrawElements(GL_TRIANGLES, self.numIndices, GL_UNSIGNED_SHORT, 0);
    }
}


- (void)refreshTexture:(CVPixelBufferRef)pixelBuffer
{
    if (pixelBuffer &&  _ioBufferRef) {
        CVPixelBufferRelease(_ioBufferRef);
    }
    _ioBufferRef = pixelBuffer;
}

- (void)dealloc {
    [self stopDeviceMotion];
    [self tearDownVideoCache];
    [self tearDownGL];
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)tearDownGL {
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexIndicesBufferID);
    glDeleteBuffers(1, &_vertexBufferID);
    glDeleteBuffers(1, &_vertexTexCoordID);
    
    self.program = nil;
}

- (void)tearDownVideoCache {
    [self cleanUpTextures];
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
        self.videoTextureCache = nil;
    }

}
- (void)addGesture {
    _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:_pinchRecognizer];

}

#pragma mark - Texture Cleanup

- (void)cleanUpTextures {
    if (self.lumaTexture) {
        CFRelease(_lumaTexture);
        self.lumaTexture = NULL;
    }
    
    if (self.chromaTexture) {
        CFRelease(_chromaTexture);
        self.chromaTexture = NULL;
    }
    
    // Periodic texture cache flush every frame
    if (_videoTextureCache) {
        CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    }
}

#pragma mark - Generate Sphere
//https://github.com/danginsburg/opengles-book-samples/blob/604a02cc84f9cc4369f7efe93d2a1d7f2cab2ba7/iPhone/Common/esUtil.h#L110
int esGenSphere(int numSlices, float radius, float **vertices,
                float **texCoords, uint16_t **indices, int *numVertices_out) {
    int numParallels = numSlices / 2;
    int numVertices = (numParallels + 1) * (numSlices + 1);
    int numIndices = numParallels * numSlices * 6;
    float angleStep = (2.0f * ES_PI) / ((float) numSlices);
    
    if (vertices != NULL) {
        *vertices = malloc(sizeof(float) * 3 * numVertices);
    }
    
    if (texCoords != NULL) {
        *texCoords = malloc(sizeof(float) * 2 * numVertices);
    }
    
    if (indices != NULL) {
        *indices = malloc(sizeof(uint16_t) * numIndices);
    }
    
    for (int i = 0; i < numParallels + 1; i++) {
        for (int j = 0; j < numSlices + 1; j++) {
            int vertex = (i * (numSlices + 1) + j) * 3;
            
            if (vertices) {
                (*vertices)[vertex + 0] = radius * sinf(angleStep * (float)i) * sinf(angleStep * (float)j);
                (*vertices)[vertex + 1] = radius * cosf(angleStep * (float)i);
                (*vertices)[vertex + 2] = radius * sinf(angleStep * (float)i) * cosf(angleStep * (float)j);
            }
            
            if (texCoords) {
                int texIndex = (i * (numSlices + 1) + j) * 2;
                (*texCoords)[texIndex + 0] = (float)j / (float)numSlices;
                (*texCoords)[texIndex + 1] = 1.0f - ((float)i / (float)numParallels);
            }
        }
    }
    
    // Generate the indices
    if (indices != NULL) {
        uint16_t *indexBuf = (*indices);
        for (int i = 0; i < numParallels ; i++) {
            for (int j = 0; j < numSlices; j++) {
                *indexBuf++ = i * (numSlices + 1) + j;
                *indexBuf++ = (i + 1) * (numSlices + 1) + j;
                *indexBuf++ = (i + 1) * (numSlices + 1) + (j + 1);
                
                *indexBuf++ = i * (numSlices + 1) + j;
                *indexBuf++ = (i + 1) * (numSlices + 1) + (j + 1);
                *indexBuf++ = i * (numSlices + 1) + (j + 1);
            }
        }
    }
    
    if (numVertices_out) {
        *numVertices_out = numVertices;
    }
    
    return numIndices;
}

#pragma mark - Setup OpenGL

- (void)setupGL
{
    switch (_srcType) {
        case ZLCPanoSRCTypeStream:
            [self setupStreamGL];
            break;
        case ZLCPanoSRCTypePicture:
            [self setupPictureGL];
            break;
        default:
            break;
    }
}

- (void)setupStreamGL
{
    [EAGLContext setCurrentContext:self.context];
    [self buildProgram];
    [self setupBuffers];
    [self setupVideoCache];
    [self.program use];
    glUniform1i(uniforms[UNIFORM_Y], 0);
    glUniform1i(uniforms[UNIFORM_UV], 1);
    glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, kColorConversion709);
}

- (void)setupPictureGL
{
    [EAGLContext setCurrentContext:self.context];
    glEnable(GL_DEPTH_TEST);
    GLfloat *vVertices = NULL;
    GLfloat *vTextCoord = NULL;
    GLushort *indices = NULL;
    int numVertices = 0;
    self.numIndices = esGenSphere(200, 1.0, &vVertices, &vTextCoord, &indices, &numVertices);
    glGenBuffers(1, &_vertexIndicesBufferID);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.vertexIndicesBufferID);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.numIndices*sizeof(GLushort), indices, GL_STATIC_DRAW);
    glGenBuffers(1, &_vertexBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBufferID);
    glBufferData(GL_ARRAY_BUFFER, numVertices*3*sizeof(GLfloat), vVertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*3, NULL);
    glGenBuffers(1, &_vertexTexCoordID);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexTexCoordID);
    glBufferData(GL_ARRAY_BUFFER, numVertices*2*sizeof(GLfloat), vTextCoord, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);
}

- (void)setupBuffers {
    GLfloat *vVertices = NULL;
    GLfloat *vTextCoord = NULL;
    GLushort *indices = NULL;
    int numVertices = 0;
    self.numIndices = esGenSphere(SphereSliceNum, SphereRadius, &vVertices, &vTextCoord, &indices, &numVertices);
    //Indices
    glGenBuffers(1, &_vertexIndicesBufferID);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.vertexIndicesBufferID);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.numIndices*sizeof(GLushort), indices, GL_STATIC_DRAW);
    // Vertex
    glGenBuffers(1, &_vertexBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBufferID);
    glBufferData(GL_ARRAY_BUFFER, numVertices*3*sizeof(GLfloat), vVertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*3, NULL);
    // Texture Coordinates
    glGenBuffers(1, &_vertexTexCoordID);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexTexCoordID);
    glBufferData(GL_ARRAY_BUFFER, numVertices*2*sizeof(GLfloat), vTextCoord, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(self.vertexTexCoordAttributeIndex);
    glVertexAttribPointer(self.vertexTexCoordAttributeIndex, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);
}

- (void)setupVideoCache {
    if (!self.videoTextureCache) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_videoTextureCache);
        if (err != noErr) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
            return;
        }
    }
}

#pragma mark - Device Motion

- (void)startDeviceMotion {
    self.isUsingMotion = NO;
    self.fingerRotationX = 0;
    self.fingerRotationY = 0;
    self.fingerRotationZ = 0;
    self.isUsingMotion = YES;
}

- (void)stopDeviceMotion {
    self.isUsingMotion = NO;
    self.fingerRotationX = 0;
    self.fingerRotationY = 0;
    self.fingerRotationZ = 0;
    self.isUsingMotion = NO;
}

#pragma mark - GLKViewController Subclass
#pragma mark 手势功能



-(void)update
{
//渐变动画参数
    n_overtrue = (n_overtrue > self.overture)?(n_overtrue-(n_overtrue-self.overture)/(n_overtrue_rate)):(n_overtrue+(self.overture -n_overtrue)/(n_overtrue_rate));
    n_perspectofs = (n_perspectofs > self.perspectOffset)?(n_perspectofs-(n_perspectofs-self.perspectOffset)/(n_perspectofs_rate)):(n_perspectofs+(self.perspectOffset -n_perspectofs)/(n_perspectofs_rate));
    n_fingerX = (n_fingerX > self.fingerRotationX)?(n_fingerX-(n_fingerX-self.fingerRotationX)/(n_finger_rate)):(n_fingerX+(self.fingerRotationX -n_fingerX)/(n_finger_rate));
    n_fingerY = (n_fingerY > self.fingerRotationY)?(n_fingerY-(n_fingerY-self.fingerRotationY)/(n_finger_rate)):(n_fingerY+(self.fingerRotationY -n_fingerY)/(n_finger_rate));
    if (self.fingerRotationY == 0) {
        n_fingerY = 0;
    }
    if (self.srcType == ZLCPanoSRCTypeStream)
    {
        if (_isUsingMotion)
        {
            if (self.nowOrientation == INITOrientation_Portrait)
            {
                [self update_alltype_portait_usingMotion];
                
            }else if(self.nowOrientation == INITOrientation_LandscapeRight)
            {
                [self update_stream_landscape_usingMotion];
            }
        }else
        {
            [self update_alltype_allOrientation_notUsingMotion];
        }
    }else if(self.srcType == ZLCPanoSRCTypePicture)
    {
        if (_isUsingMotion) {
            
            [self update_alltype_portait_usingMotion];
        }else
        {
            [self update_alltype_allOrientation_notUsingMotion];
        }
    }
}

#pragma mark 横屏陀螺仪情况_数据流
-(void)update_stream_landscape_usingMotion
{
    float aspect =   (self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(n_overtrue), aspect, 0.1f, 10000.0f);
    projectionMatrix = GLKMatrix4Rotate(projectionMatrix, ES_PI, self.camRotX, 0.0f, 0.0f);
    if (_perspectiveMode == ZLCPanoPerspectModeFisheye) {
        projectionMatrix = GLKMatrix4Translate(projectionMatrix, 0, 0, 0.05f);
    }
    CMDeviceMotion *deviceMotion = self.motionManager.deviceMotion;
    double w  = deviceMotion.attitude.quaternion.w;
    double wy = deviceMotion.attitude.quaternion.x;
    double wx = deviceMotion.attitude.quaternion.y;
    double wz = deviceMotion.attitude.quaternion.z;
    GLKQuaternion quaternion = GLKQuaternionMake(wx, wy, wz, w);
    GLKMatrix4 rotation = GLKMatrix4MakeWithQuaternion(quaternion);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, self.scale, self.scale, self.scale);
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0, 0, 1.f);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, rotation);
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.offset);
    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, n_fingerY);
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, M_PI_2);
    self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, GL_FALSE, self.modelViewProjectionMatrix.m);
}

#pragma mark 水平陀螺仪情况_数据流
-(void)update_alltype_portait_usingMotion
{
    float aspect =   (self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(n_overtrue), aspect, 0.1f, 10000.0f);
    projectionMatrix = GLKMatrix4Rotate(projectionMatrix, ES_PI, self.camRotX, 0.0f, 0.0f);
    if (_perspectiveMode == ZLCPanoPerspectModeFisheye) {
        projectionMatrix = GLKMatrix4Translate(projectionMatrix, 0, 0, 0.05f);
    }
    CMDeviceMotion *deviceMotion = self.motionManager.deviceMotion;
    double w  = deviceMotion.attitude.quaternion.w;
    double wx = deviceMotion.attitude.quaternion.x;
    double wy = deviceMotion.attitude.quaternion.y;
    double wz = deviceMotion.attitude.quaternion.z;
    GLKQuaternion quaternion = GLKQuaternionMake(-wx, wy, wz, w);
    GLKMatrix4 rotation = GLKMatrix4MakeWithQuaternion(quaternion);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, self.scale, self.scale, self.scale);
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0, 0, 1.f);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, rotation);
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.offset);
    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, n_fingerY); //水平滑动陀螺仪
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, M_PI_2);
    self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, GL_FALSE, self.modelViewProjectionMatrix.m);
}

#pragma mark 手势使用情况_数据流
-(void)update_alltype_allOrientation_notUsingMotion
{
    float aspect =   (self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(n_overtrue), aspect, 0.1f, 10000.0f);
    projectionMatrix = GLKMatrix4Rotate(projectionMatrix, ES_PI, self.camRotX, 0.0f, 0.0f);
    if (_perspectiveMode == ZLCPanoPerspectModeFisheye) {
        projectionMatrix = GLKMatrix4Translate(projectionMatrix, 0, 0, 0.05f);
    }
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, self.scale, self.scale, self.scale);
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0, 0, 1.f);
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, n_fingerX);
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, n_perspectofs);
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.offset);
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, n_fingerY);
    self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, GL_FALSE, self.modelViewProjectionMatrix.m);
}


#pragma mark - OpenGL Program

- (void)buildProgram {
    self.program = [[GLProgram alloc]
                    initWithVertexShaderFilename:@"Shader"
                    fragmentShaderFilename:@"Shader"];
    [self.program addAttribute:@"position"];
    [self.program addAttribute:@"texCoord"];
    
    if (![self.program link]) {
        self.program = nil;
        NSAssert(NO, @"Falied to link HalfSpherical shaders");
    }
    self.vertexTexCoordAttributeIndex = [self.program attributeIndex:@"texCoord"];
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = [self.program uniformIndex:@"modelViewProjectionMatrix"];
    uniforms[UNIFORM_Y] = [self.program uniformIndex:@"SamplerY"];
    uniforms[UNIFORM_UV] = [self.program uniformIndex:@"SamplerUV"];
    uniforms[UNIFORM_COLOR_CONVERSION_MATRIX] = [self.program uniformIndex:@"colorConversionMatrix"];
}

#pragma mark - Touch Event

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if(self.isUsingMotion) return;
    for (UITouch *touch in touches) {
        [_currentTouches addObject:touch];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGFloat offset = ([self isActualRefresh])?(-1.f):(1.f);
    UITouch *touch = [touches anyObject];
    float distX = [touch locationInView:touch.view].x - [touch previousLocationInView:touch.view].x;
    float distY = [touch locationInView:touch.view].y - [touch previousLocationInView:touch.view].y;
    distX *= 0.005*offset;
    distY *= -0.005;
    float moveX = (distY *  self.overture / 100);
    float moveY = (distX *  self.overture / 100);
    self.fingerRotationX += moveX*(FINGER_SENSITIVE_X);
    self.fingerRotationY -= moveY*(FINGER_SENSITIVE_Y);
    self.fingerRotationZ += 0;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isUsingMotion) return;
    for (UITouch *touch in touches) {
        [self.currentTouches removeObject:touch];
    }
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        [self.currentTouches removeObject:touch];
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer {
    self.overture /= recognizer.scale;
    [self updateOverture];
}

-(void)singleTapRecognizer:(UITapGestureRecognizer *)tapgesture
{
}

- (void)updateFingerParameters
{
    self.fingerRotationX = 0;
    self.fingerRotationY = 0;
    self.fingerRotationZ = 0;

}
- (void)updateOverture
{
    _pinchRecognizer.scale = 1.0f;
    if (self.overture > self.maximumOverture) {
        self.overture = self.maximumOverture;
    }
    if (self.overture < self.minimumOverture) {
        self.overture = self.minimumOverture;
    }
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeRight;
}


@end
