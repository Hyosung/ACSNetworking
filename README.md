# ACSNetworking
ACSNetworking是一个依赖于[AFNetworking](https://github.com/AFNetworking/AFNetworking)的网络请求的库，其主要目的是为了使用更便捷，更高效。初次写库，如有什么写的不对或是不好的地方还请在[Issues](https://github.com/Hyosung/ACSNetworking/issues)指出。

## 怎么导入项目中？

#### 直接导入
[下载 ACSNetworking](https://github.com/Hyosung/ACSNetworking/archive/master.zip) 然后导入到你的iOS或者OSX项目中，注意你还得[下载 AFNetworking](https://github.com/AFNetworking/AFNetworking/archive/master.zip)
#### 使用Cocoapods

**Podfile**

```ruby
platform :ios, '7.0'
pod "ACSNetworking", "~> 1.0.0"
```

### Requester

- `ACSURLHTTPRequester`
- `ACSFileDownloader`
- `ACSFileUploader`

### Cache

- `ACSCache`

### Configuration

- `ACSNetworkConfiguration`

### Reachability

- `ACSNetworkReachabilityManager`

### RequestManager

- `ACSRequestManager`

## 用法

#### `GET` Request

```objective-c
// Block
ACSRequestManager *manager = [ACSRequestManager manager];
ACSURLHTTPRequester *requester = ACSCreateGETRequester([NSURL URLWithString:@"http://example.com/resources.json"], nil, ^(id result, NSError *error) {
        if (result) {
            NSLog(@"responseObject %@", result);
        }
        else {
            NSLog(@"Error %@", error);
        }
    });
[manager fetchDataFromRequester:requester];
```

```objective-c
// Delegate
ACSRequestManager *manager = [ACSRequestManager manager];
ACSURLHTTPRequester *requester = ACSCreateGETRequester([NSURL URLWithString:@"http://example.com/resources.json"], nil, NULL);
requester.delegate = self;
[manager fetchDataFromRequester:requester];

- (void)request:(id<ACSURLHTTPRequest>)requester didFailWithError:(NSError *)error {
    NSLog(@"Error %@", error);
}

- (void)request:(id<ACSURLHTTPRequest>)requester didReceiveData:(id)data {
    NSLog(@"responseObject %@", data);
}
```

#### `GET` Download Request

```objective-c
// Block
ACSRequestManager *manager = [ACSRequestManager manager];
ACSFileDownloader *requester = ACSCreateDownloader([NSURL URLWithString:@"http://example.com/resources.json"],
                                                   ^(ACSRequestProgress progress, NSString *filePath, NSError *error) {
                                                       if (error) {
                                                           NSLog(@"Error %@", error);
                                                       }
                                                       else {
                                                           if (!filePath) {
                                                               NSLog(@"responseObject %@", filePath);
                                                           }
                                                           else {
                                                               NSLog(@"Progress %f", progress.progressValue);
                                                           }
                                                       }
                                                   });
[manager fetchDataFromRequester:requester];
```

```objective-c
//Delegate
......
```

#### `POST` URL-Form-Encoded Request

```objective-c
// Block
ACSRequestManager *manager = [ACSRequestManager manager];
ACSURLHTTPRequester *requester = ACSCreatePOSTRequester([NSURL URLWithString:@"http://example.com/resources.json"], nil, ^(id result, NSError *error) {
        if (result) {
            NSLog(@"responseObject %@", result);
        }
        else {
            NSLog(@"Error %@", error);
        }
    });
[manager fetchDataFromRequester:requester];
```

```objective-c
// Delegate
ACSRequestManager *manager = [ACSRequestManager manager];
ACSURLHTTPRequester *requester = ACSCreatePOSTRequester([NSURL URLWithString:@"http://example.com/resources.json"], nil, NULL);
requester.delegate = self;
[manager fetchDataFromRequester:requester];

- (void)request:(id<ACSURLHTTPRequest>)requester didFailWithError:(NSError *)error {
    NSLog(@"Error %@", error);
}

- (void)request:(id<ACSURLHTTPRequest>)requester didReceiveData:(id)data {
    NSLog(@"responseObject %@", data);
}
```

#### `POST` Multi-Part Request

```objective-c
// Block
ACSRequestManager *manager = [ACSRequestManager manager];
NSDictionary *parameters = @{@"foo": @"bar"};
UIImage *image = [UIImage imageNamed:@"imageName"];
NSDictionary *fileInfo = @{@"image": image};
//fileInfo = @{@"image": @"file://path/to/image.png"};
//fileInfo = @{@"image": [NSURL URLWithString:@"file://path/to/image.png"]};
//fileInfo = @{@"image": [NSData dataWithContentsOfFile:@"file://path/to/image.png"]};
ACSFileUploader *requester = ACSCreateUploader([NSURL URLWithString:@"http://example.com/resources.json"],
                                                fileInfo,
                                                ^(ACSRequestProgress progress, id result, NSError *error) {
                                                    if (error) {
                                                       NSLog(@"Error %@", error);
                                                    }
                                                    else {
                                                        if (result) {
                                                            NSLog(@"responseObject %@", result);
                                                        }
                                                        else {
                                                            NSLog(@"Progress %f", progress.progressValue);
                                                        }
                                                    }
                                                });
requester.parameters = parameters;
[manager fetchDataFromRequester:requester];
```

```objective-c
// Delegate
ACSRequestManager *manager = [ACSRequestManager manager];
NSDictionary *parameters = @{@"foo": @"bar"};
UIImage *image = [UIImage imageNamed:@"imageName"];
NSDictionary *fileInfo = @{@"image": image};
ACSFileUploader *requester = ACSCreateUploader([NSURL URLWithString:@"http://example.com/resources.json"],
                                                fileInfo,
                                                NULL);
requester.parameters = parameters;
requester.delegate = self;
[manager fetchDataFromRequester:requester];
......
- (void)request:(id<ACSURLFileRequest>)requester didFileProgressing:(ACSRequestProgress)progress {
    NSLog(@"Progress %f", progress.progressValue);
}
```

## License

ACSNetworking is released under the MIT license. See LICENSE for details.
