//
//  RKObjectMappingOperationSpec.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h" 
#import "RKObjectMapperError.h"

@interface TestMappable : NSObject {
    NSURL* _url;
    NSString* _boolString;
}

@property (nonatomic, retain) NSURL* url;
@property (nonatomic, retain) NSString* boolString;
@property (nonatomic, retain) NSNumber* boolNumber;

@end

@implementation TestMappable

@synthesize url = _url;
@synthesize boolString = _boolString;
@synthesize boolNumber = _boolNumber;

- (BOOL)validateBoolString:(id *)ioValue error:(NSError **)outError {
    if ([(NSObject*)*ioValue isKindOfClass:[NSString class]] && [(NSString*)*ioValue isEqualToString:@"FAIL"]) {
        *outError = [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectMapperErrorUnmappableContent userInfo:nil];
        return NO;
    } else if ([(NSObject*)*ioValue isKindOfClass:[NSString class]] && [(NSString*)*ioValue isEqualToString:@"REJECT"]) {
        return NO;
    }
    
    return YES;
}

@end

@interface RKObjectMappingOperationSpec : RKSpec {
    
}

@end

@implementation RKObjectMappingOperationSpec

- (void)itShouldNotUpdateEqualURLProperties {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"url", nil];
    NSURL* url1 = [NSURL URLWithString:@"http://www.restkit.org"];
    NSURL* url2 = [NSURL URLWithString:@"http://www.restkit.org"];
    assertThatBool(url1 == url2, is(equalToBool(NO)));
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    [object setUrl:url1];
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:url2, @"url", nil];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThatBool(object.url == url1, is(equalToBool(YES)));
    [operation release];
}

- (void)itShouldSuccessfullyMapBoolsToStrings {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"boolString", nil];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
    id data = [parser objectFromString:@"{\"boolString\":true}" error:nil];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:data destinationObject:object mapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.boolString, is(equalTo(@"true")));
    [operation release];
}

- (void)itShouldSuccessfullyMapTrueBoolsToNSNumbers {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"boolNumber", nil];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
    id data = [parser objectFromString:@"{\"boolNumber\":true}" error:nil];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:data destinationObject:object mapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThatInt([object.boolNumber intValue], is(equalToInt(1)));
    [operation release];
}

- (void)itShouldSuccessfullyMapFalseBoolsToNSNumbers {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"boolNumber", nil];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
    id data = [parser objectFromString:@"{\"boolNumber\":false}" error:nil];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:data destinationObject:object mapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThatInt([object.boolNumber intValue], is(equalToInt(0)));
    [operation release];
}

- (void)itShouldSuccessfullyMapNumbersToStrings {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapKeyPath:@"number" toAttribute:@"boolString"];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
    id data = [parser objectFromString:@"{\"number\":123}" error:nil];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:data destinationObject:object mapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.boolString, is(equalTo(@"123")));
    [operation release];
}

- (void)itShouldFailTheMappingOperationIfKeyValueValidationSetsAnError {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"boolString", nil];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    NSDictionary* dictionary = [NSDictionary dictionaryWithObject:@"FAIL" forKey:@"boolString"];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(NO)));
    assertThat(error, isNot(nilValue()));
    [operation release];
}

- (void)itShouldNotSetTheAttributeIfKeyValueValidationReturnsNo {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"boolString", nil];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    object.boolString = @"should not change";
    NSDictionary* dictionary = [NSDictionary dictionaryWithObject:@"REJECT" forKey:@"boolString"];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.boolString, is(equalTo(@"should not change")));
    [operation release];
}

@end
