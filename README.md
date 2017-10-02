我们在项目中有时会碰到视频相关的需求，一般的可以分为几种情况：



### 1. 简单的视频开发，对界面无要求，可直接使用系统UIImagePickerController。

（1）使用UIImagePickerController视频录制，短视频10秒钟

（2）在UIImagePickerController代理方法 didFinishPickingMediaWithInfo，使用`AVAssetExportSession`转码MP4（一般要兼容Android播放，iOS默认是mov格式）

（3）使用AFNetWorking上传到服务器

（4）网络请求，使用AVPlayerViewControlller在线播放视频流。(在iOS9之后,苹果已经弃用MPMoviePlayerController)



####1.1 UIImagePickerController

UIImagePickerController继承于UINavigationController。UIImagePickerController可以用来选择照片，它还可以用来拍照和录制视频。

1. **sourceType：** 拾取源类型，sourceType是枚举类型：

   UIImagePickerControllerSourceTypePhotoLibrary：照片库，默认值
   UIImagePickerControllerSourceTypeCamera：摄像头
   UIImagePickerControllerSourceTypeSavedPhotosAlbum：相簿

2. **mediaTypes：**媒体类型,默认情况下此数组包含kUTTypeImage，所以拍照时可以不用设置；但是当要录像的时候必须设置，可以设置为kUTTypeVideo（视频，但不带声音）或者kUTTypeMovie（视频并带有声音）

3. **videoMaximumDuration：**视频最大录制时长，默认为10 s 

4. **videoQuality：**视频质量，枚举类型：
   UIImagePickerControllerQualityTypeHigh：高清质量
   UIImagePickerControllerQualityTypeMedium：中等质量，适合WiFi传输
   UIImagePickerControllerQualityTypeLow：低质量，适合蜂窝网传输
   UIImagePickerControllerQualityType640x480：640*480
   UIImagePickerControllerQualityTypeIFrame1280x720：1280*720
   UIImagePickerControllerQualityTypeIFrame960x540：960*540

5. **cameraDevice：**摄像头设备，cameraDevice是枚举类型：
   UIImagePickerControllerCameraDeviceRear：前置摄像头
   UIImagePickerControllerCameraDeviceFront：后置摄像头

6. **cameraFlashMode：**闪光灯模式，枚举类型：UIImagePickerControllerCameraFlashModeOff：关闭闪光灯UIImagePickerControllerCameraFlashModeAuto：闪光灯自动UIImagePickerControllerCameraFlashModeOn：打开闪光灯

7. `(BOOL)isSourceTypeAvailable:(UIImagePickerControllerSourceType)sourceType`指定的源类型是否可用，sourceType是枚举类型：
   UIImagePickerControllerSourceTypePhotoLibrary：照片库
   UIImagePickerControllerSourceTypeCamera：摄像头
   UIImagePickerControllerSourceTypeSavedPhotosAlbum：相簿

8. ```objective-c
   UIImageWriteToSavedPhotosAlbum(UIImage *image, id completionTarget, SEL completionSelector, void *contextInfo)	//保存照片到相簿
   ```

9. ```objective-c
   UISaveVideoAtPathToSavedPhotosAlbum(NSString *videoPath, id completionTarget, SEL completionSelector, void *contextInfo)	//保存视频到相簿
   ```

   示例：

   ```objective-c
       //使用UIImagePickerController视频录制
       UIImagePickerController *picker = [[UIImagePickerController alloc] init];
       picker.delegate = self;
       if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
           picker.sourceType = UIImagePickerControllerSourceTypeCamera;
       }
       
       //mediaTypes设置摄影还是拍照
       //kUTTypeImage 对应拍照
       //kUTTypeMovie  对应摄像
   //    NSString *requiredMediaType = ( NSString *)kUTTypeImage;
       NSString *requiredMediaType1 = ( NSString *)kUTTypeMovie;
       NSArray *arrMediaTypes=[NSArray arrayWithObjects:requiredMediaType1,nil];
       picker.mediaTypes = arrMediaTypes;
   //    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;默认是中等
       picker.videoMaximumDuration = 60.; //60秒
       [self presentViewController:picker animated:YES completion:^{
           
       }];
   ```

   ​


#### 1.2 AVAsset

AVAsset是一个抽象类和不可变类。定义了媒体资源混合呈现的方式。主要用于获取多媒体信息，既然是一个抽象类，那么当然不能直接使用。可以让开发者在处理流媒体时提供一种简单统一的方式，它并不是媒体资源,但是它可以作为时基媒体的容器。

实际上是创建的是它的子类**AVUrlAsset**的一个实例。通过**AVUrlAsset**我们可以创建一个带选项(optional)的asset，以提供更精确的时长和计时信息。比如通过AVURLAsset的duration计算视频时长。

```objective-c
/**
 获取视频时长

 @param url url
 @return s
 */
- (CGFloat)getVideoLength:(NSURL *)url{
    AVURLAsset *avUrl = [AVURLAsset assetWithURL:url];
    CMTime time = [avUrl duration];
    int second = ceil(time.value/time.timescale);
    return second;
}
```



#### 1.3 AVAssetExportSession

AVAssetExportSession是用于为AVAsset源对象进行转码输出，可进行格式转码，压缩等。

```objective-c
 AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];

    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse= YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:nil];
```



#### 1.4 AVAssetImageGenerator

AVAssetImageGenerator能够取出视频中每一帧的缩略图或者预览图。举个🌰：

```objective-c
  // result
    UIImage *image = nil;
    
    // AVAssetImageGenerator
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    
    // calculate the midpoint time of video
    Float64 duration = CMTimeGetSeconds([asset duration]);
    // 取某个帧的时间，参数一表示哪个时间（秒），参数二表示每秒多少帧
    // 通常来说，600是一个常用的公共参数，苹果有说明:
    // 24 frames per second (fps) for film, 30 fps for NTSC (used for TV in North America and
    // Japan), and 25 fps for PAL (used for TV in Europe).
    // Using a timescale of 600, you can exactly represent any number of frames in these systems
    CMTime midpoint = CMTimeMakeWithSeconds(duration / 2.0, 600);
    
    // get the image from
    NSError *error = nil;
    CMTime actualTime;
    // Returns a CFRetained CGImageRef for an asset at or near the specified time.
    // So we should mannully release it
    CGImageRef centerFrameImage = [imageGenerator copyCGImageAtTime:midpoint
                                                         actualTime:&actualTime
                                                              error:&error];
    
    if (centerFrameImage != NULL) {
        image = [[UIImage alloc] initWithCGImage:centerFrameImage];
        // Release the CFRetained image
        CGImageRelease(centerFrameImage);
    }
    
    return image;
```



#### 1.5 AVPlayerViewControlller

AVPlayerViewController是UIViewController的子类,它可以用来显示AVPlayer对象的视觉内容和标准的播放控制。

具体AVPlayer自定义下面再说，回到AVPlayerViewController，它不支持UI自定义，实现比较简单，代码如下：

```objective-c
    AVPlayer *player = [AVPlayer playerWithURL:self.finalURL];
    AVPlayerViewController *playerVC = [[AVPlayerViewController alloc] init];
    playerVC.player = player;
    playerVC.view.frame = self.view.frame;
    [self.view addSubview:playerVC.view];
    [playerVC.player play];
```

具体代码可下载Demo



<br>

### 2. 复杂的业务需求，需要自定义视频界面

（1）使用AVFoundation拍照和录制视频，自定义界面

（2）使用`AVAssetExportSession`转码MP4（一般要兼容Android播放，iOS默认是mov格式）

（3）使用AFNetWorking上传到服务器

（4）网络请求，使用AVFoundation框架的AVPlayer来自定义播放界面，在线播放视频流。播放又分为先下后播和边下边播。



#### 2.1 AVFoundation 

AVFoundation是一个可以用来使用和创建基于时间的视听媒体的框架，它提供了一个能使用基于时间的视听数据的详细级别的Objective-C接口。例如：您可以用它来检查，创建，编辑或是重新编码媒体文件。也可以从设备中获取输入流，在视频实时播放时操作和回放。


![avfoundation.png](http://upload-images.jianshu.io/upload_images/3261360-d12a3745f769a4b3.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


 **AVCaptureSession**：媒体（音、视频）捕获会话，负责把捕获的音视频数据输出到输出设备中。一个AVCaptureSession可以有多个输入输出。
 **AVCaptureDevice** ：输入设备，包括麦克风、摄像头，通过该对象可以设置物理设备的一些属性（例如相机聚焦、白平衡等）。
 **AVCaptureDeviceInput** ：设备输入数据管理对象，可以根据AVCaptureDevice创建对应的AVCaptureDeviceInput对象，该对象将会被添加到AVCaptureSession中管理。
 **AVCaptureVideoPreviewLayer** ：相机拍摄预览图层，是CALayer的子类，使用该对象可以实时查看拍照或视频录制效果，创建该对象需要指定对应的 AVCaptureSession对象。

 **AVCaptureOutput** ：输出数据管理对象，用于接收各类输出数据，通常使用对应的子类AVCaptureAudioDataOutput、AVCaptureStillImageOutput、AVCaptureVideoDataOutput、AVCaptureFileOutput, 该对象将会被添加到AVCaptureSession中管理。


![relationship.png](http://upload-images.jianshu.io/upload_images/3261360-974ec0a9a82596a8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


建立视频拍摄的步骤如下:

1. 创建AVCaptureSession对象。

```objective-c
// 创建会话 (AVCaptureSession) 对象。
_captureSession = [[AVCaptureSession alloc] init];
if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
    // 设置会话的 sessionPreset 属性, 这个属性影响视频的分辨率
    [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
}
```

2. 使用AVCaptureDevice的静态方法获得需要使用的设备，例如拍照和录像就需要获得摄像头设备，录音就要获得麦克风设备。

```objective-c
// 获取摄像头输入设备， 创建 AVCaptureDeviceInput 对象
// 在获取摄像头的时候，摄像头分为前后摄像头，我们创建了一个方法通过用摄像头的位置来获取摄像头 
AVCaptureDevice *videoCaptureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
if (!captureDevice) {
    NSLog(@"---- 取得后置摄像头时出现问题---- ");
    return;
}

// 添加一个音频输入设备
// 直接可以拿数组中的数组中的第一个
AVCaptureDevice *audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
```

3. 利用输入设备AVCaptureDevice初始化AVCaptureDeviceInput对象。

```objective-c
// 视频输入对象
// 根据输入设备初始化输入对象，用户获取输入数据
_videoCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
if (error) {
    NSLog(@"---- 取得设备输入对象时出错 ------ %@",error);
    return;
} 

//  音频输入对象
//根据输入设备初始化设备输入对象，用于获得输入数据
_audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:&error];
if (error) {
    NSLog(@"取得设备输入对象时出错 ------ %@",error);
    return;
}
```

4. 初始化输出数据管理对象，如果要拍照就初始化AVCaptureStillImageOutput对象；如果拍摄视频就初始化AVCaptureMovieFileOutput对象。

```objective-c
// 拍摄视频输出对象
// 初始化输出设备对象，用户获取输出数据
_caputureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
```

5. 将数据输入对象AVCaptureDeviceInput、数据输出对象AVCaptureOutput添加到媒体会话管理对象AVCaptureSession中。

```objective-c
// 将视频输入对象添加到会话 (AVCaptureSession) 中
if ([_captureSession canAddInput:_videoCaptureDeviceInput]) {
    [_captureSession addInput:_videoCaptureDeviceInput];
}

// 将音频输入对象添加到会话 (AVCaptureSession) 中
if ([_captureSession canAddInput:_captureDeviceInput]) {
    [_captureSession addInput:audioCaptureDeviceInput];
    AVCaptureConnection *captureConnection = [_caputureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    // 标识视频录入时稳定音频流的接受，我们这里设置为自动
    if ([captureConnection isVideoStabilizationSupported]) {
        captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
}
```

6. 创建视频预览图层AVCaptureVideoPreviewLayer并指定媒体会话，添加图层到显示容器中，调用AVCaptureSession的startRuning方法开始捕获。

```objective-c
// 通过会话 (AVCaptureSession) 创建预览层
_captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];

// 显示在视图表面的图层
CALayer *layer = self.viewContrain.layer;
layer.masksToBounds = true;

_captureVideoPreviewLayer.frame = layer.bounds;
_captureVideoPreviewLayer.masksToBounds = true;
_captureVideoPreviewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//填充模式
[layer addSublayer:_captureVideoPreviewLayer];

// 让会话（AVCaptureSession）勾搭好输入输出，然后把视图渲染到预览层上
[_captureSession startRunning];
```

7. 将捕获的音频或视频数据输出到指定文件。

```objective-c
//创建一个拍摄的按钮，当我们点击这个按钮就会触发视频录制，并将这个录制的视频放到 temp 文件夹中
- (IBAction)takeMovie:(id)sender {
[(UIButton *)sender setSelected:![(UIButton *)sender isSelected]];
if ([(UIButton *)sender isSelected]) {
     AVCaptureConnection *captureConnection=[self.caputureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    // 开启视频防抖模式
    AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
    if ([self.captureDeviceInput.device.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
        [captureConnection setPreferredVideoStabilizationMode:stabilizationMode];
    }

    //如果支持多任务则则开始多任务
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
       self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    }
    // 预览图层和视频方向保持一致,这个属性设置很重要，如果不设置，那么出来的视频图像可以是倒向左边的。
    captureConnection.videoOrientation=[self.captureVideoPreviewLayer connection].videoOrientation;

   // 设置视频输出的文件路径，这里设置为 temp 文件
    NSString *outputFielPath=[NSTemporaryDirectory() stringByAppendingString:MOVIEPATH];

    // 路径转换成 URL 要用这个方法，用 NSBundle 方法转换成 URL 的话可能会出现读取不到路径的错误
    NSURL *fileUrl=[NSURL fileURLWithPath:outputFielPath];

   // 往路径的 URL 开始写入录像 Buffer ,边录边写
    [self.caputureMovieFileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
}
else {
   // 取消视频拍摄
    [self.caputureMovieFileOutput stopRecording];
    [self.captureSession stopRunning];
    [self completeHandle];
}
}
```

当然我们录制的开始与结束都是有监听方法的，**AVCaptureFileOutputRecordingDelegate** 这个代理里面就有我们想要做的

```objective-c
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
   NSLog(@"---- 开始录制 ----");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"---- 录制结束 ----");
}
```








####2.2 AVPlayer自定义播放器

AVPlayer是用于管理媒体资产的播放和定时的控制器对象，它提供了控制播放器的有运输行为的接口，如它可以在媒体的时限内播放，暂停，和改变播放的速度，并有定位各个动态点的能力。我们可以使用AVPlayer来播放本地和远程的视频媒体文件，如QuickTime影片和MP3音频文件，以及视听媒体使用HTTP流媒体直播服务。

AVPlayer本身并不能显示视频，而且它也不像AVPlayerViewController有一个view属性。如果AVPlayer要显示必须创建一个播放器层AVPlayerLayer用于展示，播放器层继承于CALayer，有了AVPlayerLayer之添加到控制器视图的layer中即可。要使用AVPlayer首先了解一下几个常用的类：

- AVPlayer：播放器，将数据解码处理成为图像和声音。


- AVAsset：主要用于获取多媒体信息，是一个抽象类，不能直接使用。

- AVURLAsset：AVAsset的子类，可以根据一个URL路径创建一个包含媒体信息的AVURLAsset对象。负责网络连接，请求数据。

- AVPlayerItem：一个媒体资源管理对象，管理者视频的一些基本信息和状态，负责数据的获取与分发；一个AVPlayerItem对应着一个视频资源。可以添加观察者监听播放源的3个状态：

  ```objective-c
  //添加观察者
  [_playerItem 
      addObserver:self 
      forKeyPath:@"status"
      options:NSKeyValueObservingOptionNew 
      context:nil];
  //对播放源的三个状态(status)
  AVPlayerItemStatusReadyToPlay  //播放源准备好
  AVPlayerItemStatusUnknown	   //播放源未知
  AVPlayerItemStatusFailed	   //播放源失败
  ```

- AVPlayerLayer：图像层，AVPlayer的图像要通过AVPlayerLayer呈现。


![avplayerLayer_2x.png](http://upload-images.jianshu.io/upload_images/3261360-ba98c400b1ca5ed9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
<br>

使用 `AVPlayer` 对象控制资产的播放。在播放期间，可以使用一个 [AVPlayerItem](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVPlayerItem_Class/index.html#//apple_ref/occ/cl/AVPlayerItem) 实例去管理资产作为一个整体的显示状态，[AVPlayerItemTrack](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVPlayerItemTrack_Class/index.html#//apple_ref/occ/cl/AVPlayerItemTrack) 对象来管理一个单独轨道的显示状态。使用 [AVPlayerLayer](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVPlayerLayer_Class/index.html#//apple_ref/occ/cl/AVPlayerLayer) 显示视频。

需要注意的是，AVPlayer的模式是，你不要主动调用play方法播放视频，而是等待AVPlayerItem告诉你，我已经准备好播放了，你现在可以播放了，所以我们要监听AVPlayerItem的状态，通过添加监听者的方式获取AVPlayerItem的状态。当监听到播放器已经准备好播放的时候，就可以调用play方法。

> 创建一个视频播放器的思路:
>
> - 创建一个view用来放置AVPlayerLayer
> - 设置AVPlayer AVPlayerItem 并将 AVPlayer放到AVPlayerLayer中，在将AVPlayerLayer添加到[view.layer addSubLayer]中
> - 添加观察者，观察播放源的状态
>   1. 如果状态是AVPlayerItemStatusReadyToPlay就开始播放
> - 在做一些功能上的操作

```objective-c
//获取url 本地url
    //NSURL *url = [[NSBundle mainBundle]URLForResource:@"视频" withExtension:@"mp4"];
    NSURL *url = [NSURL URLWithString:@"http://XXX.mp4"];
    //创建playerItem
    _playerItem = [AVPlayerItem playerItemWithURL:url];
    //添加item的观察者 监听播放源的播放状态(status)
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //创建playerItem
    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    //创建playerLayer
    _playerLayer=[AVPlayerLayer playerLayerWithPlayer:_player];
    //设置_layer的frame
    _playerLayer.frame=CGRectMake(_playerView.frame.origin.x, _playerView.frame.origin.y, _playerView.frame.size.width,300);
    //添加到_playerView中
    [_playerView.layer addSublayer:_playerLayer];
```

```objective-c
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
  if ([keyPath isEqualToString:@"status"]) {
      AVPlayerItem *playerItem = (AVPlayerItem *)object;
      AVPlayerItemStatus status = playerItem.status;
      switch (status) {
          case AVPlayerItemStatusUnknown:{

          }
              break;
          case AVPlayerItemStatusReadyToPlay:{
              [self.player play];
              self.player.muted = self.mute;
              // 显示图像逻辑
              [self handleShowViewSublayers];

          }
              break;
          case AVPlayerItemStatusFailed:{

          }
              break;
          default:
              break;
      }
  }
}
```



#### 2.3 边播放，边缓存

如果直接使用上面这种方式， URL 通过 AVPlayer 播放，系统并不会做缓存处理，等下次再播又要重新下载，对流量和网络状态来说也是蛮尴尬的。那如何做到边播放，边缓存，下载完成还能直接从本地读取呢？

答案就是：**在本地开启一个 http 服务器，把需要缓存的请求地址指向本地服务器，并带上真正的 url 地址。**


![cachePlan.png](http://upload-images.jianshu.io/upload_images/3261360-e2e9c001c1831976.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


当我们给播放器设置好url等一些参数后，播放器就会向url所在的服务器发送请求(请求参数有两个值，一个是offset偏移量，另一个是length长度，其实就相当于NSRange一样)，服务器就根据range参数给播放器返回数据。这就是AVPlayer播放大致的原理。

**AVAssetResourceLoaderDelegate**

我们在使用AVURLAsset时，实际上是可以设置AVAssetResourceLoaderDelegate代理。

```objective-c
AVURLAsset *urlAsset = ...
[urlAsset.resourceLoader setDelegate:<AVAssetResourceLoaderDelegate> queue:dispatch_get_main_queue()];
```

AVAssetResourceLoader是负责数据加载的，最最重要的是我们只要遵守了AVAssetResourceLoaderDelegate，就可以成为它的代理，成为它的代理以后，数据加载可能会通过代理方法询问我们。

只要找一个对象实现了 `AVAssetResourceLoaderDelegate` 这个协议的方法，丢给 asset，再把 asset 丢给 AVPlayer，AVPlayer 在执行播放的时候就会去问这个 delegate：喂，你能不能播放这个 url 啊？然后会触发下面这个方法：

```
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest 
```

在 `AVAssetResourceLoadingRequest` 里面，`request` 代表原始的请求，由于 AVPlayer 是会触发分片下载的策略，还需要从`dataRequest` 中得到请求范围的信息。有了请求地址和请求范围，我们就可以重新创建一个设置了请求 Range 头的 NSURLRequest 对象，让下载器去下载这个文件的 Range 范围内的数据。

而对应的下载我们可以使用NSURLSession 实现断点下载、离线断点下载等。

```objective-c
// 替代NSMutableURL, 可以动态修改scheme
NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
actualURLComponents.scheme = @"http";

// 创建请求
NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[actualURLComponents URL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];

// 修改请求数据范围
if (offset > 0 && self.videoLength > 0) {
    [request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld",(unsigned long)offset, (unsigned long)self.videoLength - 1] forHTTPHeaderField:@"Range"];
}

// 重置
[self.session invalidateAndCancel];

// 创建Session，并设置代理
self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];

// 创建会话对象
NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];

// 开始下载
[dataTask resume];
```

我们可以在NSURLSession的代理方法中获得下载的数据，拿到下载的数据以后，为了解决内存暴涨的问题，我们使用NSOutputStream，将数据直接写入到硬盘中存放临时文件的文件夹。在请求结束的时候，我们判断是否成功下载好文件，如果下载成功，就把这个文件转移到我们的存储成功文件的文件夹。如果下载失败，就把临时数据删除。

```objective-c
// 1.接收到服务器响应的时候
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler;

// 2.接收到服务器返回数据的时候调用,会调用多次
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data;

// 3.请求结束的时候调用(成功|失败),如果失败那么error有值
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error;
```

#### 


代理对象需要实现的功能

- 1.接收视频播放器的请求，并根据请求的range向服务器请求本地没有获得的数据

- 2.缓存向服务器请求回的数据到本地

- 3.如果向服务器的请求出现错误，需要通知给视频播放器，以便视频播放器对用户进行提示



视频播放器处理流程

- 1.当开始播放视频时，通过视频url判断本地cache中是否已经缓存当前视频，如果有，则直接播放本地cache中视频
- 2.如果本地cache中没有视频，则视频播放器向代理请求数据
- 3.加载视频时展示正在加载的提示（菊花转）
- 4.如果可以正常播放视频，则去掉加载提示，播放视频，如果加载失败，去掉加载提示并显示失败提示
- 5.在播放过程中如果由于网络过慢或拖拽原因导致没有播放数据时，要展示加载提示，跳转到第4步



代理对象处理流程

- 1.当视频播放器向代理请求dataRequest时，判断代理是否已经向服务器发起了请求，如果没有，则发起下载整个视频文件的请求
- 2.如果代理已经和服务器建立链接，则判断当前的dataRequest请求的offset是否大于当前已经缓存的文件的offset，如果大于则取消当前与服务器的请求，并从offset开始到文件尾向服务器发起请求（此时应该是由于播放器向后拖拽，并且超过了已缓存的数据时才会出现）
- 3.如果当前的dataRequest请求的offset小于已经缓存的文件的offset，同时大于代理向服务器请求的range的offset，说明有一部分已经缓存的数据可以传给播放器，则将这部分数据返回给播放器（此时应该是由于播放器向前拖拽，请求的数据已经缓存过才会出现）
- 4.如果当前的dataRequest请求的offset小于代理向服务器请求的range的offset，则取消当前与服务器的请求，并从offset开始到文件尾向服务器发起请求（此时应该是由于播放器向前拖拽，并且超过了已缓存的数据时才会出现）
- 5.只要代理重新向服务器发起请求，就会导致缓存的数据不连续，则加载结束后不用将缓存的数据放入本地cache
- 6.如果代理和服务器的链接超时，重试一次，如果还是错误则通知播放器网络错误
- 7.如果服务器返回其他错误，则代理通知播放器网络错误







<br>

###3. 在线直播和视频点播，开发流程：

AVPlayer + [ffmpeg](http://ffmpeg.org/) / ijkplayer

我们平时看到的视频文件有许多格式，比如 avi， mkv， rmvb， mov， mp4等等，这些被称为[容器](http://en.wikipedia.org/wiki/Digital_container_format)（[Container](http://wiki.multimedia.cx/index.php?title=Category:Container_Formats)）， 不同的容器格式规定了其中音视频数据的组织方式（也包括其他数据，比如字幕等）。容器中一般会封装有视频和音频轨，也称为视频流（stream）和音频 流，播放视频文件的第一步就是根据视频文件的格式，解析（demux）出其中封装的视频流、音频流以及字幕（如果有的话），解析的数据读到包 （packet）中，每个包里保存的是视频帧（frame）或音频帧，然后分别对视频帧和音频帧调用相应的解码器（decoder）进行解码，比如使用 H.264编码的视频和MP3编码的音频，会相应的调用H.264解码器和MP3解码器，解码之后得到的就是原始的图像(YUV or RGB)和声音(PCM)数据，然后根据同步好的时间将图像显示到屏幕上，将声音输出到声卡，最终就是我们看到的视频。

FFmpeg的API就是根据这个过程设计的，ffmpeg是一个多平台多媒体处理工具，处理视频和音频的功能非常强大，能够解码，编码， 转码，复用，解复用，流，过滤器和播放大部分的视频格式。ffmpeg的代码是包括两部分的，一部分是library，一部分是tool。api都是在library里面，如果直接调api来操作视频的话，就需要写c或者c++了。另一部分是tool，使用的是命令行，则不需要自己去编码来实现视频操作的流程。实际上tool只不过把命令行转换为api的操作而已。



**ijkplayer**

ijkplayer 框架是B站（BiliBili）提供了一个开源的流媒体解决方案，集成了 ffmpeg。使用 ijkplayer 框架我们可以很方便地实现视频直播功能（HTTP/RTMP/RTSP 这几种直播源都支持）。并且同时支持 iOS 和 Android 。

<br>

**一个完整直播app实现流程**

`1.采集、2.滤镜处理、3.编码、4.推流、5.CDN分发、6.拉流、7.解码、8.播放、9.聊天互动`


![live_broadcast.png](http://upload-images.jianshu.io/upload_images/3261360-c8e4a0d83ebe8769.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

具体到各个环节：推流端（采集、美颜处理、编码、推流）、服务端处理（转码、录制、截图、鉴黄）、播放器（拉流、解码、渲染）、互动系统（聊天室、礼物系统、赞）



**一个完整直播app技术点**


![technical_point.jpg](http://upload-images.jianshu.io/upload_images/3261360-a763132a3600a272.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


`流媒体开发`:网络层(socket或st)负责传输，协议层(rtmp或hls)负责网络打包，封装层(flv、ts)负责编解码数据的封装，编码层(h.264和aac)负责图像，音频压缩。

`帧`:每帧代表一幅静止的图像

```
GOP
```

- 直播的数据，其实是一组图片，包括I帧、P帧、B帧，当用户第一次观看的时候，会寻找I帧，而播放器会到服务器寻找到最近的I帧反馈给用户。因此，GOP Cache增加了端到端延迟，因为它必须要拿到最近的I帧
- GOP Cache的长度越长，画面质量越好

`码率`：图片进行压缩后每秒显示的数据量。

```
帧率
```

- 由于人类眼睛的特殊生理结构，如果所看画面之帧率高于16的时候，就会认为是连贯的，此现象称之为视觉暂留。并且当帧速达到一定数值后，再增长的话，人眼也不容易察觉到有明显的流畅度提升了。

`分辨率`：(矩形)图片的长度和宽度，即图片的尺寸

`压缩前的每秒数据量`:帧率X分辨率(单位应该是若干个字节) 

`压缩比`:压缩前的每秒数据量/码率 （对于同一个视频源并采用同一种视频编码算法，则：压缩比越高，画面质量越差。）　

`视频文件格式`：`文件的后缀`，比如`.wmv,.mov,.mp4,.mp3,.avi`,

- `主要用处`，根据文件格式，系统会自动判断用什么软件打开,
  注意: 随意修改文件格式，对文件的本身不会造成太大的影响，比如把avi改成mp4,文件还是avi.

`视频封装格式`：`一种储存视频信息的容器`，流式封装可以有`TS、FLV`等，索引式的封装有`MP4,MOV,AVI`等，

- `主要作用`：一个视频文件往往会包含图像和音频，还有一些配置信息(如图像和音频的关联，如何解码它们等)：这些内容需要按照一定的规则组织、封装起来.
- `注意`：会发现封装格式跟文件格式一样，因为一般视频文件格式的后缀名即采用相应的视频封装格式的名称,所以视频文件格式就是视频封装格式。

`视频封装格式和视频压缩编码标准`：就好像项目工程和编程语言，封装格式就是一个项目的工程，视频编码方式就是编程语言，一个项目工程可以用不同语言开发。





<br>

另这里有几款优秀的播放器控件可去GitHub下载学习：

[ZFPlayer - 使用人数也很多。基于AVPlayer，一个播放器的基本功能几乎很全面了](https://github.com/renzifeng/ZFPlayer)

[mobileplayer-ios - 纯 Swift 。文档详细，功能齐全](https://github.com/mobileplayer/mobileplayer-ios)

[KRVideoPlayer - 36kr 开源项目。类似Weico的播放器](https://github.com/36Kr-Mobile/KRVideoPlayer)

[SGPlayer - 支持 VR 播放](https://github.com/libobjc/SGPlayer)

[VKVideoPlayer - VKVideoPlayer is the same battle tested video player used in our Viki iOS App enjoyed by millions of users all around the world](https://github.com/viki-org/VKVideoPlayer)

[WMPlayer - AVPlayer的封装，继承UIView，想怎么玩就怎么玩。支持播放mp4、m3u8、3gp、mov，网络和本地视频同时支持。全屏和小屏播放同时支持。自动感应旋转屏](https://github.com/zhengwenming/WMPlayer)

[Player - ▶️ video player in Swift, simple way to play and stream media on iOS/tvOS](https://github.com/piemonte/Player)



<br>

参考文献：

[AVAsset](https://developer.apple.com/documentation/avfoundation/avasset)

[AVFoundation Programming Guide(官方文档翻译)完整版](http://yoferzhang.com/post/20160724AVFoundation/)

[iOS录制视频](http://www.jianshu.com/p/7c57c58c253d)

[iOS录制（或选择）视频，压缩、上传（整理）](http://blog.csdn.net/xingxingleo/article/details/51000511)

[iOS视频录制压缩](http://www.winnhe.com/2016/03/12/iOS%E8%A7%86%E9%A2%91%E5%BD%95%E5%88%B6%E5%8E%8B%E7%BC%A9/)

[iOS上传视频到服务器](http://tech.yunyingxbs.com/article/detail/id/275.html)

[iOS视频边下边播--缓存播放数据流](http://www.jianshu.com/p/990ee3db0563)

[IOS 微信聊天发送小视频的秘密(AVAssetReader+AVAssetReaderTrackOutput播放视频)](http://www.jianshu.com/p/3d5ccbde0de1)

[可能是目前最好的 AVPlayer 音视频缓存方案](https://mp.weixin.qq.com/s/v1sw_Sb8oKeZ8sWyjBUXGA##)

[[iOS]仿微博视频边下边播之封装播放器](http://www.jianshu.com/p/0d4588a7540f)

[【补充】NSURLSession 详解离线断点下载的实现](http://www.jianshu.com/p/b63217ff7287)

[[iOS: FFmpeg的使用一](http://www.cnblogs.com/XYQ-208910/p/5651166.html)](http://www.cnblogs.com/XYQ-208910/p/5651166.html)

[iOS 利用FFmpeg 开发音视频流（二）——Mac 系统上编译 iOS 可用的FFmpeg 库](http://www.jianshu.com/p/ec432a8f5729)

[iOS中集成ijkplayer视频直播框架](http://www.jianshu.com/p/1f06b27b3ac0)

[iOS 直播 —— 推流](http://www.jianshu.com/p/447df915984e)

[【如何快速的开发一个完整的iOS直播app】(原理篇)](http://www.jianshu.com/p/bd42bacbe4cc)

[iOS流媒体开发之三：HLS直播（M3U8）回看和下载功能的实现](http://www.jianshu.com/p/b0db841ed6d3%20)