//
//  CitiesManager.m
//  Cities
//
//  Created by Jovito Royeca on 20/01/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

#import "CitiesManager.h"

@implementation CitiesManager

+ (instancetype)sharedInstance {
    static CitiesManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CitiesManager alloc] init];
        // Do any other initialisation stuff here
        [sharedInstance loadCities];
        
    });
    return sharedInstance;
}

- (void) loadCities {
    if (!self.cities) {
        self.cities = [[NSMutableArray alloc] init];

        NSString *path = [NSBundle.mainBundle pathForResource: @"cities" ofType: @"json" inDirectory: @"data"];
        
        if (path) {
            if ([NSFileManager.defaultManager fileExistsAtPath: path]) {
                NSURL *url = [NSURL fileURLWithPath: path];
                NSData *data = [[NSData alloc] initWithContentsOfURL: url];
                NSArray *array = [NSJSONSerialization JSONObjectWithData: data options:kNilOptions error: nil];
                NSMutableArray *newArray = [[NSMutableArray alloc] init];
                
                for (NSDictionary *dict in array) {
                    City *city = [[City alloc] init];
                    NSDictionary *coord = dict[@"coord"];
                    
                    city.cityId = dict[@"_id"];
                    city.name = dict[@"name"];
                    city.country = dict[@"country"];
                    city.latitude = coord[@"lat"];
                    city.longitude = coord[@"lon"];
                    
                    [newArray addObject: city];
                }
                
                NSArray *sortedArray = [newArray sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                    NSString *nameA = [(City*)a name];
                    NSString *nameB = [(City*)b name];
                    
                    return [nameA.lowercaseString compare:nameB.lowercaseString];
                }];
                
                self.cities = [NSMutableArray arrayWithArray:sortedArray];
            }
        }
    }
}

- (NSArray*_Nonnull) filterCities:(NSString* _Nullable) filter {
    NSArray *results;
    
    if (filter) {
        NSPredicate *predicate;
        
        if (filter.length == 0) {
            results = self.cities;
        } else {
            predicate = [NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", filter];
            results = [self.cities filteredArrayUsingPredicate:predicate];
        }
        
    } else {
        results = self.cities;
    }
    
    return results;
}

- (void) createSectionIndexTitles {
    self.sectionIndexTitles = [[NSMutableDictionary alloc] init];
    
    for (City *city in self.cities) {
        NSInteger sentinel = 1;
        NSString *prefix = [city.name substringToIndex: sentinel].uppercaseString;
        // remove the accents
        prefix = [prefix stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale: [NSLocale localeWithLocaleIdentifier:@"en"]].uppercaseString;
        
        // convert numbers to "#"
        if ([prefix rangeOfCharacterFromSet: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location == NSNotFound) {
            prefix = [[NSMutableString alloc] initWithString:@"#"];
            // ignore other characters
        } else if ([prefix rangeOfCharacterFromSet: NSCharacterSet.alphanumericCharacterSet].location == NSNotFound) {
            do {
                prefix = [city.name substringWithRange: NSMakeRange(sentinel, 1)].uppercaseString;
                // remove the accents
                prefix = [prefix stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale: [NSLocale localeWithLocaleIdentifier:@"en"]].uppercaseString;
                
                sentinel++;
            } while ([prefix rangeOfCharacterFromSet: NSCharacterSet.alphanumericCharacterSet].location == NSNotFound);
        }
        
        NSMutableArray *array = self.sectionIndexTitles[prefix];
        // we found a previous array, just append the city
        if (array) {
            [array addObject: city];
            // create a new array for the prefix
        } else {
            NSMutableArray *array = [[NSMutableArray alloc] init];
            [array addObject: city];
            self.sectionIndexTitles[prefix] = array;
        }
    }
    
    // sort alphabetically
    self.sortedSectionIndexTitles = [self.sectionIndexTitles.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

@end
