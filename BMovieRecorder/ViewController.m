//
//  ViewController.m
//  BMovieRecorder
//
//  Created by SapientiaWind on 17/3/28.
//  Copyright © 2017年 Social Capital Consulting Limited. All rights reserved.
//

#import "ViewController.h"
#import "ProgressView.h"
#import "GPUImage.h"
#import <AssetsLibrary/ALAssetsLibrary.h>
@interface ViewController (){
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
}
@property (nonatomic, strong) ProgressView *pro_View;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) NSURL *movieURL;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initCamera];
    [self SetUpUI];
}

- (void)SetUpUI{
    [self initCamera];
    
    CGRect rect = CGRectMake((self.view.frame.size.width - 80) * 0.5, self.view.frame.size.height * 0.8, 80, 80);
    //初始圆环 (设置button的border 在设置画圆 总有像素差)
    ProgressView *proview = [[ProgressView alloc] initWithFrame:rect];
    proview.backgroundColor = [UIColor clearColor];
    [self.view addSubview:proview];
    proview.beginAngle = -M_PI_2;
    proview.finishAngle = -M_PI_2;
    proview.color = [UIColor greenColor];
    proview.lineWidth = 4;
    proview.isCompleted = YES;
    [proview setNeedsDisplay];
    //做动画的圆
    _pro_View = [[ProgressView alloc] initWithFrame:rect];
    _pro_View.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_pro_View];
    _pro_View.beginAngle = -M_PI_2;
    _pro_View.finishAngle = -M_PI_2;
    _pro_View.color = [UIColor whiteColor];
    _pro_View.lineWidth = 4;
    
    UILongPressGestureRecognizer *longPr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(pressView:)];
    longPr.minimumPressDuration = 0.01;
    [_pro_View addGestureRecognizer:longPr];
}

- (void)reDrawView{
    [_pro_View setNeedsDisplay];
    if(_pro_View.finishAngle > 2 * M_PI - (M_PI_2 * 1)){
        [self endMovieWriter];
        [_timer invalidate]; // 停止计时器
        _timer = nil;
    }
}
#pragma mark 长按开始录制
- (void)pressView:(UILongPressGestureRecognizer *)sender{
    
    if(sender.state == UIGestureRecognizerStateBegan){
        [_timer invalidate];
        _timer = nil;
        //重置录制ProgressView
        _pro_View.beginAngle = -M_PI_2;
        _pro_View.finishAngle = -M_PI_2;
        _pro_View.color = [UIColor whiteColor];
        _pro_View.lineWidth = 4;
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(reDrawView) userInfo:nil repeats:true];
        //设置即使拖动也会不间断计时
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
        [_timer fire];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"开始录制");
            videoCamera.audioEncodingTarget = movieWriter;
            [movieWriter startRecording];
        });
    }
    
    if(sender.state == UIGestureRecognizerStateEnded){
        [self endMovieWriter];
    }
}

- (void)endMovieWriter{
    [_timer invalidate];
    _timer = nil;
    _pro_View.finishAngle = -M_PI_2;
    [_pro_View setNeedsDisplay];
    
    [filter removeTarget:movieWriter];
    //        videoCamera.audioEncodingTarget = nil;
    [movieWriter finishRecording];
    NSLog(@"录制完成");
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:_movieURL])
    {
        [library writeVideoAtPathToSavedPhotosAlbum:_movieURL completionBlock:^(NSURL *assetURL, NSError *error)
         {
             dispatch_async(dispatch_get_global_queue(0, 0), ^{
                 //不调用[filter useNextFrameForImageCapture]; 如果后面添加滤镜会Crash
                 [filter useNextFrameForImageCapture];
                 //写入相册成功后移除本地的文件 防止下次写入失败
                 [[NSFileManager defaultManager] removeItemAtURL:_movieURL error:nil];//2
                 //重新实例化movieWriter对象 不然第二次录制崩溃
                 //执行了[filter removeTarget:movieWriter];后movieWriter需要重新实例化
                 movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:_movieURL size:CGSizeMake(480.0, 640.0)];
                 movieWriter.encodingLiveVideo = YES;
                 
                 [videoCamera addTarget:movieWriter];//4
                 [filter addTarget:movieWriter];
                 
                 if (error) {
                     NSLog(@"写入失败 Error== %@",error);
                 } else {
                     NSLog(@"写入成功");
                 }
             });
         }];
    }
}

- (void)initCamera{
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    videoCamera.horizontallyMirrorRearFacingCamera = NO;
    
    //设置滤镜
    filter = [[GPUImageSepiaFilter alloc] init];
    [videoCamera addTarget:filter];
    //显示画面
    GPUImageView *filterView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:filterView];
    //设置存储路径
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    _movieURL = [NSURL fileURLWithPath:pathToMovie];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:_movieURL size:CGSizeMake(480.0, 640.0)];
    movieWriter.encodingLiveVideo = YES;
    //直接加入音频  加入音频会有卡顿现象 需要提前加入
    videoCamera.audioEncodingTarget = movieWriter;
    [filter addTarget:movieWriter];
    [filter addTarget:filterView];
    
    [videoCamera startCameraCapture];
}



@end
