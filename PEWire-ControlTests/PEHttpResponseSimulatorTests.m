//
//  PEHttpResponseSimulatorTests.m
//
// Copyright (c) 2014-2015 PEWire-Control
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <AFNetworking/AFNetworking.h>
#import "PEHttpResponseSimulator.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(PEHttpResponseSimulatorSpec)

describe(@"PEHttpResponseSimulator", ^{
    __block NSDateFormatter *rfc1123;
    __block AFHTTPRequestOperationManager *requestOpMgr;

    context(@"Testing the Simulators", ^{
        __block BOOL isConnFailure;
        __block NSHTTPURLResponse *resp;
        __block NSArray *simRespCookies;
        __block NSDictionary *simRespHdrs;
        NSURL *url = [NSURL URLWithString:@"http://test.example.com/base"];
        beforeAll(^{
            requestOpMgr = [[AFHTTPRequestOperationManager alloc]
                             initWithBaseURL:url];
            [requestOpMgr setResponseSerializer:[AFHTTPResponseSerializer
                                                  serializer]];
            simRespHdrs = @{@"Content-Type" : @"text/plain"};
            simRespCookies = @[
                [NSHTTPCookie cookieWithProperties:@{
                   NSHTTPCookieName : @"C1",
                   NSHTTPCookieValue : @"C1-val",
                   NSHTTPCookieDomain : @".test.example.com",
                   NSHTTPCookiePath : @"/"}],
                [NSHTTPCookie cookieWithProperties:@{
                   NSHTTPCookieName : @"C2",
                   NSHTTPCookieValue : @"C2-val",
                   NSHTTPCookieDomain : @"test.example.com",
                   NSHTTPCookiePath : @"/"}]
              ];
          });

        beforeEach(^{
            [PEHttpResponseSimulator clearSimulations];
            isConnFailure = NO;
            resp = nil;
          });

        void (^vanillaInputsAndInvocationExpectationsBlk) (void) = ^ (void) {
          NSDictionary *actualRespHdrs;
          __block NSString *actualRespBody;
          [requestOpMgr GET:@""
                 parameters:nil
                    success:^(AFHTTPRequestOperation *op, id respObj) {
              resp = [op response];
              actualRespBody = [[NSString alloc]
                                    initWithData:respObj
                                        encoding:NSUTF8StringEncoding];
            }
                    failure:^(AFHTTPRequestOperation *op, NSError *err) {
              isConnFailure = YES;
            }];

          // expectations
          [[expectFutureValue(theValue(isConnFailure)) shouldEventually] beNo];
          [[expectFutureValue(resp) shouldEventually] beNonNil];
          [[theValue([resp statusCode]) should] equal:theValue(200)];
          [actualRespBody shouldNotBeNil];
          [[actualRespBody should] equal:@"mock response body"];
          actualRespHdrs = [resp allHeaderFields];
          [[actualRespHdrs objectForKey:@"Set-Cookie"] shouldNotBeNil];
          [[[actualRespHdrs objectForKey:@"Set-Cookie"] should]
               equal:@"C1=C1-val;path=/;domain=.test.example.com;,\
C2=C2-val;path=/;domain=test.example.com;"];
          [[[actualRespHdrs objectForKey:@"Content-Type"] should]
               equal:@"text/plain"];
        };

        void (^requestNotSimulatedExpectationsBlk) (void) = ^ (void) {
          [requestOpMgr GET:@""
                 parameters:nil
                    success:^(AFHTTPRequestOperation *op, id respObj) {
              resp = [op response];
            }
          failure:^(AFHTTPRequestOperation *op, NSError *err) {
              isConnFailure = YES;
            }];

          // expectations
          [[expectFutureValue(theValue(isConnFailure)) shouldEventually] beYes];
          [[expectFutureValue(resp) shouldEventually] beNil];
        };

        void (^simulatedFailureExpectationsBlk) (void) = ^ (void) {
          __block NSInteger errCode;
          [requestOpMgr GET:@""
                 parameters:nil
                    success:^(AFHTTPRequestOperation *op, id respObj) {
              resp = [op response];
            }
          failure:^(AFHTTPRequestOperation *op, NSError *err) {
              isConnFailure = YES;
              errCode = [err code];
            }];

          // expectations
          [[expectFutureValue(theValue(isConnFailure)) shouldEventually] beYes];
          [[expectFutureValue(resp) shouldEventually] beNil];
          [[theValue(errCode) should]
              beBetween:theValue(NSURLErrorDownloadDecodingFailedToComplete)
                    and:theValue(NSURLErrorCancelled)];
        };

        it(@"Works as expected simulating a DNS failure", ^{
            [PEHttpResponseSimulator simulateDNSFailureForRequestUrl:url
                                                andRequestHttpMethod:@"GET"];
            simulatedFailureExpectationsBlk();
          });

        it(@"Works as expected simulating a connection timeout", ^{
            [PEHttpResponseSimulator
              simulateConnectionTimedOutForRequestUrl:url
                                 andRequestHttpMethod:@"GET"];
            simulatedFailureExpectationsBlk();
          });

        it(@"Works as expected simulating a cannot-connect-to-host error", ^{
            [PEHttpResponseSimulator
              simulateCannotConnectToHostForRequestUrl:url
                                  andRequestHttpMethod:@"GET"];
            simulatedFailureExpectationsBlk();
          });

        it(@"Works as expected simulating a not-connected-to-internet error", ^{
            [PEHttpResponseSimulator
              simulateNotConnectedToInternetForRequestUrl:url
                                     andRequestHttpMethod:@"GET"];
            simulatedFailureExpectationsBlk();
          });

        it(@"Works as expected simulating a connection-lost error", ^{
            [PEHttpResponseSimulator simulateConnectionLostForRequestUrl:url
                                                    andRequestHttpMethod:@"GET"];
            simulatedFailureExpectationsBlk();
          });

        it(@"Works as expected when request method doesn't match", ^{
            [PEHttpResponseSimulator
              simulateResponseWithUTF8Body:@"mock response body"
                                statusCode:200
                                   headers:simRespHdrs
                                   cookies:simRespCookies
                             forRequestUrl:url
                      andRequestHttpMethod:@"POST"
                            requestLatency:0
                           responseLatency:0];
            requestNotSimulatedExpectationsBlk();
           });

        it(@"Works as expected when request URL path doesn't match", ^{
            [PEHttpResponseSimulator
              simulateResponseWithUTF8Body:@"mock response body"
                                statusCode:200
                                   headers:simRespHdrs
                                   cookies:simRespCookies
                             forRequestUrl:[NSURL URLWithString:@"http://\
something.else.com"]
                      andRequestHttpMethod:@"GET"
                            requestLatency:0
                           responseLatency:0];
            requestNotSimulatedExpectationsBlk();
           });

        it(@"Works using vanilla inputs and invocation", ^{
            [PEHttpResponseSimulator
              simulateResponseWithUTF8Body:@"mock response body"
                                statusCode:200
                                   headers:simRespHdrs
                                   cookies:simRespCookies
                             forRequestUrl:url
                      andRequestHttpMethod:@"GET"
                            requestLatency:0
                           responseLatency:0];
            vanillaInputsAndInvocationExpectationsBlk();
          });

        it(@"Works using vanilla inputs and invocation using mock-resp \
convenience method", ^{
             PEHttpResponse *mockResponse =
               [[PEHttpResponse alloc]
                 initWithRequestUrl:
                   [NSURL URLWithString:@"http://test.example.com/base"]];
             [mockResponse setStatusCode:200];
             [mockResponse setRequestMethod:@"GET"];
             [mockResponse setBody:@"mock response body"];
             [mockResponse addHeaderWithName:@"Content-Type"
                                       value:@"text/plain"];
             [mockResponse addCookieWithName:@"C1"
                                       value:@"C1-val"
                                        path:@"/"
                                      domain:@".test.example.com"
                                    isSecure:NO
                                     expires:nil
                                      maxAge:0];
             [mockResponse addCookieWithName:@"C2"
                                       value:@"C2-val"
                                        path:@"/"
                                      domain:nil
                                    isSecure:NO
                                     expires:nil
                                      maxAge:0];
             [PEHttpResponseSimulator simulateResponseFromMock:mockResponse
                                                requestLatency:0
                                               responseLatency:0];
             vanillaInputsAndInvocationExpectationsBlk();
           });

        it(@"Works using vanilla inputs and invocation using xml-based \
convenience method", ^{
             NSString *xmlMockResp = @"<http-response statusCode=\"200\">\
<annotation name=\"sample success response\"\
            host=\"test.example.com\"\
            port=\"80\"\
            scheme=\"http\"\
            uri-path=\"/base\"\
            request-method=\"GET\">This is the description for this mock response.</annotation>\
<headers>\
  <header name=\"Content-Type\" value=\"text/plain\" />\
</headers>\
<cookies>\
  <cookie name=\"C1\"\
          value=\"C1-val\"\
          path=\"/\"\
          domain=\".test.example.com\" />\
  <cookie name=\"C2\"\
          value=\"C2-val\"\
          path=\"/\" />\
</cookies>\
<body><![CDATA[mock response body]]></body>\
</http-response>";
             [PEHttpResponseSimulator simulateResponseFromXml:xmlMockResp
                                               requestLatency:0
                                              responseLatency:0];
             vanillaInputsAndInvocationExpectationsBlk();
           });
      });

    context(@"Testing the Helpers", ^{
        beforeAll(^{
            rfc1123 = [[NSDateFormatter alloc] init];
            rfc1123.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
            rfc1123.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            rfc1123.dateFormat = @"EEE',' dd-MMM-yyyy HH':'mm':'ss z";
          });

        context(@"RFC2109 cookie format helper function", ^{
            it(@"works with 1 cookie", ^{
                PEHttpResponse *mockResp =
                  [[PEHttpResponse alloc]
                    initWithRequestUrl:
                      [NSURL URLWithString:@"http://example.com"]];
                [mockResp addCookieWithName:@"c1"
                                      value:@"c1-val"
                                       path:@"/c1"
                                     domain:@".example.com"
                                   isSecure:YES
                                    expires:nil
                                     maxAge:21];
                NSString *cookieStr =
                  [PEHttpResponseSimulator
                    cookiesToRfc2109Format:[mockResp cookies]];
                [cookieStr shouldNotBeNil];
                [[cookieStr should] startWithString:@"c1=c1-val;\
path=/c1;domain=.example.com;Secure;expires="];
              });

            it(@"works with 2 cookies", ^{
                PEHttpResponse *mockResp =
                  [[PEHttpResponse alloc]
                    initWithRequestUrl:
                      [NSURL URLWithString:@"http://example.com"]];
                NSDate *expiresDt =
                  [rfc1123 dateFromString:@"Fri, 15-Nov-2013 16:11:04 GMT"];
                [mockResp addCookieWithName:@"a1"
                                      value:@"a1-val"
                                       path:@"/a1"
                                     domain:@".a1.example.com"
                                   isSecure:YES
                                    expires:expiresDt
                                     maxAge:0];
                [mockResp addCookieWithName:@"a2"
                                      value:@"a2-val"
                                       path:@"/a2"
                                     domain:@".a2.example.com"
                                   isSecure:NO
                                    expires:nil
                                     maxAge:11];
                NSString *cookieStr =
                  [PEHttpResponseSimulator
                    cookiesToRfc2109Format:[mockResp cookies]];
                [cookieStr shouldNotBeNil];
                [[cookieStr should] startWithString:@"a1=a1-val;path=/a1;\
domain=.a1.example.com;Secure;expires=Fri, 15-Nov-2013 16:11:04 GMT;,\
a2=a2-val;path=/a2;domain=.a2.example.com;expires="];
              });
          });
      });
  });

SPEC_END
