//
//  MMResponseGenerator.m
//  MirrorMirror
//
//  Created by Cameron Ehrlich on 3/5/14.
//  Copyright (c) 2014 Cameron Ehrlich. All rights reserved.
//

#import "MMResponseGenerator.h"

@implementation MMResponseGenerator

+ (NSString *)getNiceThing
{
    NSArray *niceThings = @[@"Nice Things!"];
    NSUInteger randomIndex = arc4random() % [niceThings count];
    return [niceThings objectAtIndex:randomIndex];
}

+ (NSString *)getMeanThing
{
    NSArray *meanThings = @[@"Your BFF is sooooo pretty. Does that ever make you sad?",
                            @"You're like the dream girl for nerds. ",
                            @"Don't worry. By the time we're grown up, plastic surgery will probably be super cheap. ",
                            @"If you stopped spending so much money on fatty food, maybe you'd save up enough to be a part of the middle class.",
                            @"Stand up straight before your hunchback rips your shirt. ",
                            @"Good thing you're pretty because you suuuuure is stupid.",
                            @"1 + 1 is 2\nAnd number 1's not you\nGet a clue\nAnd leave alone my boo",
                            @"We'll cherish the memories, now leave our group.",
                            @"You have to be a special kind of pretty to pull of pale. You should consider tanning.",
                            @"How is possible that you're only 12 and you're already a has-been?"];
    
    NSUInteger randomIndex = arc4random() % [meanThings count];
    return [meanThings objectAtIndex:randomIndex];
}

@end
