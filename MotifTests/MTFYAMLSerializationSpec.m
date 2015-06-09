//
//  MTFYAMLSerializationSpec.m
//  Motif
//
//  Created by Eric Horacek on 5/29/15.
//  Copyright (c) 2015 Eric Horacek. All rights reserved.
//

@import Motif;
@import Specta;
@import Expecta;

#import "MTFYAMLSerialization.h"

SpecBegin(MTFYAMLSerialization)

describe(@"lifecycle", ^{
    it(@"should raise an exception on direct initalization", ^{
        expect(^{
            __unused MTFYAMLSerialization *serialization = [[MTFYAMLSerialization alloc] init];
        }).to.raise(NSInternalInconsistencyException);
    });
});

describe(@"deserialization from data", ^{
    __block NSError *error;
    __block MTFTheme *theme;

    id(^objectFromYAML)(NSString *) = ^(NSString *YAML) {
        NSData *data = [YAML dataUsingEncoding:NSUTF8StringEncoding];
        return [MTFYAMLSerialization YAMLObjectWithData:data error:&error];
    };

    beforeEach(^{
        error = nil;
        theme = nil;
    });

    it(@"should treat empty data as a nil object", ^{
        id object = [MTFYAMLSerialization YAMLObjectWithData:[NSData data] error:&error];

        expect(object).to.beNil();
        expect(error).to.beNil();
    });

    it(@"should treat garbage data as a nil object and populate the error parameter", ^{
        char byte = 0xFF;
        id object = [MTFYAMLSerialization YAMLObjectWithData:[NSData dataWithBytes:&byte length:1] error:&error];

        expect(object).to.beNil();
        expect(error).notTo.beNil();
        expect(error.domain).to.equal(MTFYAMLSerializationErrorDomain);
    });

    it(@"should treat a mapping as a dictionary", ^{
        NSDictionary *mapping = objectFromYAML(@"key1: value\nkey2: value");

        expect(mapping).notTo.beNil();
        expect(mapping).to.beKindOf(NSDictionary.class);
        expect(mapping.count).to.equal(2);
        expect(mapping[@"key1"]).to.equal(@"value");
        expect(mapping[@"key2"]).to.equal(@"value");
        expect(error).to.beNil();
    });

    it(@"should treat a braced mapping as a dictionary", ^{
        NSDictionary *mapping = objectFromYAML(@"{key1: value, key2: value}");

        expect(mapping).notTo.beNil();
        expect(mapping).to.beKindOf(NSDictionary.class);
        expect(mapping.count).to.equal(2);
        expect(mapping[@"key1"]).to.equal(@"value");
        expect(mapping[@"key2"]).to.equal(@"value");
        expect(error).to.beNil();
    });

    it(@"should treat a sequence as an array", ^{
        NSArray *sequence = objectFromYAML(@"- 1\n- 2");

        expect(sequence).notTo.beNil();
        expect(sequence).to.beKindOf(NSArray.class);
        expect(sequence.count).to.equal(2);
        expect(sequence.firstObject).to.equal(@1);
        expect(sequence.lastObject).to.equal(@2);
        expect(error).to.beNil();
    });

    it(@"should treat a bracketed sequence as an array", ^{
        NSArray *sequence = objectFromYAML(@"[1, 2]");

        expect(sequence).notTo.beNil();
        expect(sequence).to.beKindOf(NSArray.class);
        expect(sequence.count).to.equal(2);
        expect(sequence.firstObject).to.equal(@1);
        expect(sequence.lastObject).to.equal(@2);
        expect(error).to.beNil();
    });

    describe(@"with scalar values", ^{
        afterEach(^{
            expect(error).to.beNil();
        });

        it(@"should handle floats", ^{
            NSDictionary *expectedConversions = @{
                @"1.0": @(1.0), @"0.33": @(0.33),
                @"-1.4": @(-1.4), @"-2.e-2": @(-2.e-2),
            };

            for (NSString *s in expectedConversions) {
                NSNumber *expected = expectedConversions[s];
                NSNumber *number = objectFromYAML(s);

                expect(number).notTo.beNil();
                expect(number).to.beKindOf(NSNumber.class);
                expect(number.floatValue).to.beCloseTo(expected.floatValue);
            }
        });

        it(@"should handle integers", ^{
            NSNumber *number = objectFromYAML(@"1");

            expect(number).notTo.beNil();
            expect(number).to.beKindOf(NSNumber.class);
            expect(number.integerValue).to.equal(1);
        });

        it(@"should handle 'yes' boolean", ^{
            NSNumber *number = objectFromYAML(@"yes");

            expect(number).notTo.beNil();
            expect(number).to.beKindOf(NSNumber.class);
            expect(number.boolValue).to.equal(@YES);
            expect(error).to.beNil();
        });

        it(@"should handle 'no' boolean", ^{
            NSNumber *number = objectFromYAML(@"no");

            expect(number).notTo.beNil();
            expect(number).to.beKindOf(NSNumber.class);
            expect(number.boolValue).to.equal(@NO);
            expect(error).to.beNil();
        });

        it(@"should handle 'true' boolean", ^{
            NSNumber *number = objectFromYAML(@"true");

            expect(number).notTo.beNil();
            expect(number).to.beKindOf(NSNumber.class);
            expect(number.boolValue).to.equal(@YES);
            expect(error).to.beNil();
        });

        it(@"should handle 'false' boolean", ^{
            NSNumber *number = objectFromYAML(@"false");

            expect(number).notTo.beNil();
            expect(number).to.beKindOf(NSNumber.class);
            expect(number.boolValue).to.equal(@NO);
            expect(error).to.beNil();
        });

        it(@"should handle nulls", ^{
            NSNull *null = objectFromYAML(@"null");

            expect(null).notTo.beNil();
            expect(null).to.beKindOf(NSNull.class);
            expect(error).to.beNil();
        });

        it(@"should handle single-quoted strings", ^{
            NSString *string = objectFromYAML(@"'string'");

            expect(string).notTo.beNil();
            expect(string).to.beKindOf(NSString.class);
            expect(string).to.equal(@"string");
            expect(error).to.beNil();
        });

        it(@"should handle double-quoted strings", ^{
            NSString *string = objectFromYAML(@"\"string\"");

            expect(string).notTo.beNil();
            expect(string).to.beKindOf(NSString.class);
            expect(string).to.equal(@"string");
            expect(error).to.beNil();
        });

        it(@"should handle nulls with the null tag", ^{
            NSNull *null = objectFromYAML(@"!!null null");

            expect(null).notTo.beNil();
            expect(null).to.beKindOf(NSNull.class);
            expect(error).to.beNil();
        });

        it(@"should handle booleans with the bool tag", ^{
            NSNumber *number = objectFromYAML(@"!!bool false");

            expect(number).notTo.beNil();
            expect(number).to.beKindOf(NSNumber.class);
            expect(number.boolValue).to.equal(@NO);
            expect(error).to.beNil();
        });

        it(@"should handle strings with the string tag", ^{
            NSNull *number = objectFromYAML(@"!!str string");

            expect(number).notTo.beNil();
            expect(number).to.beKindOf(NSString.class);
            expect(number).to.equal(@"string");
            expect(error).to.beNil();
        });
    });

    it(@"should populate the error parameter on anchors", ^{
        id object = objectFromYAML(@"&anchor");

        expect(object).to.beNil();
        expect(error).notTo.beNil();
        expect(error.domain).to.equal(MTFYAMLSerializationErrorDomain);
    });

    it(@"should populate the error parameter on aliases", ^{
        id object = objectFromYAML(@"*alias");

        expect(object).to.beNil();
        expect(error).notTo.beNil();
        expect(error.domain).to.equal(MTFYAMLSerializationErrorDomain);
    });

    it(@"should populate the error parameter on unhandled tags", ^{
        id object = objectFromYAML(@"!!binary 1234");

        expect(object).to.beNil();
        expect(error).notTo.beNil();
        expect(error.domain).to.equal(MTFYAMLSerializationErrorDomain);
    });

    it(@"should populate the error parameter on syntax errors", ^{
        id object = objectFromYAML(@"syntax: error\n syntax: error");

        expect(object).to.beNil();
        expect(error).notTo.beNil();
        expect(error.domain).to.equal(MTFYAMLSerializationErrorDomain);
        expect(error.userInfo[MTFYAMLSerializationColumnErrorKey]).to.equal(@7);
        expect(error.userInfo[MTFYAMLSerializationLineErrorKey]).to.equal(@1);
    });
});

SpecEnd
