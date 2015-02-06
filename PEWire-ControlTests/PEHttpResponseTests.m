//
//  PEHttpResponseTests.m
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

#include "PEHttpResponse.h"
#include <Kiwi/Kiwi.h>

SPEC_BEGIN(PEHttpResponseSpec)

describe(@"HRMHttpResponse", ^{
    __block PEHttpResponse *mockHttpResp;
    __block NSDateFormatter *rfc1123;

    context(@"Normal and typical usage", ^{
        beforeEach(^{
            mockHttpResp =
              [[PEHttpResponse alloc]
                initWithRequestUrl:[NSURL URLWithString:@"http://example.com"]];
            rfc1123 = [[NSDateFormatter alloc] init];
            rfc1123.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
            rfc1123.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            rfc1123.dateFormat = @"EEE',' dd-MMM-yyyy HH':'mm':'ss z";
          });

        it(@"works under normal and typical usage", ^{
            [mockHttpResp addHeaderWithName:@"h1" value:@"h1-val"];
            [mockHttpResp addHeaderWithName:@"h2" value:@"h2-val"];
            [[[[mockHttpResp headers] objectForKey:@"h1"] should]
              equal:@"h1-val"];
            [[[[mockHttpResp headers] objectForKey:@"h2"] should]
              equal:@"h2-val"];
            NSDate *dt = [rfc1123 dateFromString:@"Fri, 10-Nov-2013 16:11:04 GMT"];
            [mockHttpResp addCookieWithName:@"c1"
                                      value:@"c1-val"
                                       path:@"/c"
                                     domain:@".test.com"
                                   isSecure:YES
                                    expires:dt
                                     maxAge:0];
            NSHTTPCookie *cookie = [[mockHttpResp cookies] objectAtIndex:0];
            [cookie shouldNotBeNil];
            [[[cookie path] should] equal:@"/c"];
            [[[cookie domain] should] equal:@".test.com"];
            [[[cookie value] should] equal:@"c1-val"];
            [[cookie expiresDate] shouldNotBeNil];
            [[[cookie expiresDate] should] equal:dt];
            [[theValue([cookie isSecure]) should] equal:theValue(YES)];

            [mockHttpResp addCookieWithName:@"c2"
                                      value:@"c2-val"
                                       path:@"/c2"
                                     domain:@".test.com"
                                   isSecure:YES
                                    expires:nil
                                     maxAge:12];
            cookie = [[mockHttpResp cookies] objectAtIndex:1];
            // remember, max-age gets translated to 'expires' by Cocoa
            [[cookie expiresDate] shouldNotBeNil];

            [mockHttpResp addCookieWithName:@"c3"
                                      value:@"c3-val"
                                       path:@"/c3"
                                     domain:@".test.com"
                                   isSecure:YES
                                    expires:nil
                                     maxAge:0];
            cookie = [[mockHttpResp cookies] objectAtIndex:2];
            [[cookie expiresDate] shouldBeNil];
          });

        it(@"works when the cookie type is not 'Secure'", ^{
            NSDate *dt = [rfc1123 dateFromString:@"Fri, 10-Nov-2013 16:11:04 GMT"];
            [mockHttpResp addCookieWithName:@"c1"
                                      value:@"c1-val"
                                       path:@"/c"
                                     domain:@".test.com"
                                   isSecure:NO
                                    expires:dt
                                     maxAge:0];
            NSHTTPCookie *cookie = [[mockHttpResp cookies] objectAtIndex:0];
            [cookie shouldNotBeNil];
            [[theValue([cookie isSecure]) should] equal:theValue(NO)];
            [[[cookie properties] objectForKey:NSHTTPCookieMaximumAge]
              shouldBeNil];
          });
      });
  });

SPEC_END
