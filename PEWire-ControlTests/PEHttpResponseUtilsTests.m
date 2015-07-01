//
//  PEHttpResponseUtilsTests.m
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

#import <XCTest/XCTest.h>
#import "PEHttpResponseUtils.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(PEHttpResponseUtilsSpec)

describe(@"PEHttpResponseUtils", ^{
  __block NSDateFormatter *rfc1123;
  
  beforeAll(^{
    rfc1123 = [[NSDateFormatter alloc] init];
    rfc1123.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    rfc1123.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    rfc1123.dateFormat = @"EEE',' dd-MMM-yyyy HH':'mm':'ss z";
  });
  
  context(@"is able to a load mock http response xml file when", ^{
    it(@"the response file contains a pointer to an external image file", ^{
      NSStringEncoding enc;
      NSError *err;
      NSBundle *bundle = [NSBundle bundleForClass:[self class]];
      NSString *path = [bundle pathForResource:@"mock-http-responses/http-response.200.2" ofType:@"xml"];
      NSString *xmlStr = [NSString stringWithContentsOfFile:path usedEncoding:&enc error:&err];
      PEHttpResponse *mockResp = [PEHttpResponseUtils mockResponseFromXml:xmlStr
                                                    pathsRelativeToBundle:bundle];
      [mockResp shouldNotBeNil];
      [[theValue([mockResp statusCode]) should] equal:theValue(200)];
      NSDictionary *hdrs = [mockResp headers];
      [hdrs shouldNotBeNil];
      [[theValue([hdrs count]) should] equal:theValue(1)];
      [[[hdrs objectForKey:@"Content-Type"] should] equal:@"image/jpg"];
      NSArray *cookies = [mockResp cookies];
      [cookies shouldNotBeNil];
      [[theValue([cookies count]) should] equal:theValue(0)];
      [[[mockResp name] should] equal:@"sample success response"];
      [[[mockResp responseDescription] should] equal:@"This is the description for this mock response."];
      [[mockResp bodyAsString] shouldBeNil];
      [[mockResp bodyAsData] shouldNotBeNil];
    });
    
    it(@"the response file contains an inline string-based body", ^{
      NSStringEncoding enc;
      NSError *err;
      NSBundle *bundle = [NSBundle bundleForClass:[self class]];
      NSString *path = [bundle pathForResource:@"mock-http-responses/http-response.200.1" ofType:@"xml"];
      NSString *xmlStr = [NSString stringWithContentsOfFile:path usedEncoding:&enc error:&err];
      PEHttpResponse *mockResp = [PEHttpResponseUtils mockResponseFromXml:xmlStr
                                                    pathsRelativeToBundle:bundle];
      [mockResp shouldNotBeNil];
      [[theValue([mockResp statusCode]) should] equal:theValue(200)];
      NSDictionary *hdrs = [mockResp headers];
      [hdrs shouldNotBeNil];
      [[theValue([hdrs count]) should] equal:theValue(5)];
      [[[hdrs objectForKey:@"Expires"] should] equal:@"Fri, 02 Dec 1995 12:00:03 GMT"];
      [[[hdrs objectForKey:@"Cache-Control"] should] equal:@"no-cache"];
      [[[hdrs objectForKey:@"Content-Type"] should] equal:@"application/xml"];
      [[[hdrs objectForKey:@"Content-Length"] should] equal:@"50"];
      [[[hdrs objectForKey:@"Content-Language"] should] equal:@"en-US"];
      NSArray *cookies = [mockResp cookies];
      [cookies shouldNotBeNil];
      [[theValue([cookies count]) should] equal:theValue(2)];
      NSHTTPCookie *cookie = [cookies firstObject];
      [[[cookie name] should] equal:@"C1"];
      [[[cookie value] should] equal:@"C1-val"];
      [[[cookie path] should] equal:@"/"];
      [[[cookie domain] should] equal:@".paulevans.name"];
      [[theValue([cookie isSecure]) should] equal:theValue(YES)];
      [[[cookie expiresDate] should] equal:[rfc1123 dateFromString:@"Sat, 16-Nov-2013 15:00:00 GMT"]];
      cookie = [cookies objectAtIndex:1];
      [[[cookie name] should] equal:@"C2"];
      [[[cookie value] should] equal:@"C2-val"];
      [[[cookie path] should] equal:@"/c2"];
      [[[cookie domain] should] equal:@".c2.paulevans.name"];
      [[theValue([cookie isSecure]) should] equal:theValue(NO)];
      [[cookie expiresDate] shouldBeNil];
      [[[mockResp bodyAsString] should] equal:@"<some-xml>this is the body!</some-xml>"];
      [[[mockResp name] should] equal:@"sample success response"];
      [[[mockResp responseDescription] should] equal:@"This is the description for this mock response."];
    });
  });
});

SPEC_END
