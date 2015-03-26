# PEWire-Control

[![Build Status](https://travis-ci.org/evanspa/PEWire-Control.svg)](https://travis-ci.org/evanspa/PEWire-Control)

An iOS static library for the easy stubbing of HTTP responses using simple XML
configuration files.  PEWire-Control is built on top of the excellent
[OHHTTPStubs iOS library](https://github.com/AliSoftware/OHHTTPStubs).

**Table of Contents**

- [Typical Usage Example](#typical-usage-example)
    - [1) Create the XML file representing a possible response from the web service](#1-create-the-xml-file-representing-a-possible-response-from-the-web-service)
    - [2) In your unit test setup code, do the following:](#2-in-your-unit-test-setup-code-do-the-following)
- [Installation with CocoaPods](#installation-with-cocoapods)

### Typical Usage Example

The typical use case for using PEWire-Control will be in the context of unit testing.  Imagine you have a unit test that exercises code that invokes some web service.

##### 1) Create the XML file representing a possible response from the web service

*You'll typically want to create a physical folder within your tests source folder; call it something like "http-mock-responses".  In Xocde, add this folder as a "reference folder" within your "Supporting Files" group within your tests group in Xcode.  Create your mock response XML files within your http-mock-responses/ folder.*

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<http-response statusCode="200">
  <annotation name="fetch success" host="example.com" port="80" scheme="http" uri-path="/fp/users"
              request-method="GET">Successful fetch of user.</annotation>
  <headers>
    <header name="Content-Type" value="application/vnd.name.paulevans.user-v0.0.1+json" />
    <header name="Last-Modified" value="Tue, 02 Sep 2014 8:03:12 GMT" />
    <header name="fp-auth-token" value="1092348123049OLSDFJLIE001234" />
  </headers>
  <cookies>
    <cookie name="cookie1"
            value="some value"
            path="/"
            secure="true"
            domain=".paulevans.name"
            expires="Sat, 16-Nov-2015 15:00:00 GMT" />
  </cookies>
  <body>
    <![CDATA[
      { "fpuser/name": "Paul Evans",
        "fpuser/email": "evansp2@gmail.com",
        "fpuser/username": "evansp2",
        "fpuser/creation-date": "Tue, 02 Sep 2014 8:03:12 GMT",
        "_links": {
          "vehicles": {
            "href": "http://example.com/fp/users/U1123409100/vehicles",
            "type": "application/vnd.name.paulevans.vehicle-v0.0.1+json"},
          "fuelpurchase-logs": {
            "href": "http://example.com/fp/users/U1123409100/fplogs",
            "type": "application/vnd.name.paulevans.fplog-v0.0.1+json"}}}
    ]]>
  </body>
</http-response>
```
Save this file as "fetch-user-success.xml" within your http-mock-responses/ folder.

##### 2) In your unit test setup code, do the following:

```objective-c
// Get the path to our mock HTTP response XML file.
NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
NSString *path = [testBundle pathForResource:@"fetch-user-success"
                                      ofType:@"xml"
                                 inDirectory:@"http-mock-responses"];
// Fake out Cocoa's URL loading system such that it will return an HTTP response as
// defined in our XML file for any GET requests to: http://example.com/fp/users.  And,
// simulate a request latency of 5 seconds.
NSError *err;
NSStringEncoding encoding;
[PEHttpResponseSimulator simulateResponseFromXml:[NSString stringWithContentsOfFile:path
                                                                       usedEncoding:&encoding
                                                                              error:&err]
                                  requestLatency:5.0
                                 responseLatency:0];
```

### Installation with CocoaPods

```ruby
pod 'PEWire-Control', '~> 1.0.1'
```
