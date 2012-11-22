//
//  HOTInflector.m
//  HOTModel
//
//  Created by Jose Avila III on 11/21/12.
//  Copyright (c) 2012 Jose Avila III. All rights reserved.
//

#import "HOTInflector.h"

@implementation HOTInflector

+(NSMutableDictionary *)_plural{
    static NSMutableDictionary* d = nil;
    
    if (d == nil)
    {
        // create dict
        d = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
             [[NSArray alloc] initWithObjects:
              [[NSArray alloc] initWithObjects:@"$1$2tatuses", @"(s)tatus$", nil],
              [[NSArray alloc] initWithObjects:@"$1zes", @"(quiz)$", nil],
              [[NSArray alloc] initWithObjects:@"$1$2en", @"^(ox)$", nil],
              [[NSArray alloc] initWithObjects:@"$1ice", @"([m|l])ouse$", nil],
              [[NSArray alloc] initWithObjects:@"$1ices", @"(matr|vert|ind)(ix|ex)$", nil],
              [[NSArray alloc] initWithObjects:@"$1es", @"(x|ch|ss|sh)$", nil],
              [[NSArray alloc] initWithObjects:@"$1ies", @"([^aeiouy]|qu)y$", nil],
              [[NSArray alloc] initWithObjects:@"$1s", @"(hive)$", nil],
              [[NSArray alloc] initWithObjects:@"$1$2ves", @"(?:([^f])fe|([lr])f)$", nil],
              [[NSArray alloc] initWithObjects:@"ses", @"sis$", nil],
              [[NSArray alloc] initWithObjects:@"$1a", @"([ti])um$", nil],
              [[NSArray alloc] initWithObjects:@"$1eople", @"(p)erson$", nil],
              [[NSArray alloc] initWithObjects:@"$1en", @"(m)an$", nil],
              [[NSArray alloc] initWithObjects:@"$1hildren", @"(c)hild$", nil],
              [[NSArray alloc] initWithObjects:@"$1$2oes", @"(buffal|tomat)o$", nil],
              [[NSArray alloc] initWithObjects:@"$1i", @"(alumn|bacill|cact|foc|fung|nucle|radi|stimul|syllab|termin|vir)us$", nil],
              [[NSArray alloc] initWithObjects:@"uses", @"us$", nil],
              [[NSArray alloc] initWithObjects:@"$1es", @"(alias)$", nil],
              [[NSArray alloc] initWithObjects:@"$1es", @"(ax|cris|test)is$", nil],
              [[NSArray alloc] initWithObjects:@"s", @"s$", nil],
              [[NSArray alloc] initWithObjects:@"$1s", @"^$", nil],
              [[NSArray alloc] initWithObjects:@"s", @"$", nil],
              nil],@"rules",
             [[NSArray alloc] initWithObjects:
              @".*[nrlm]ese",
              @".*deer",
              @".*fish",
              @".*measles",
              @".*ois",
              @".*pox",
              @".*sheep",
              @"people",
              nil], @"uninflected",
             [[NSMutableDictionary alloc] initWithObjectsAndKeys:
              @"atlases", @"atlas",
              @"beefs", @"beef",
              @"brothers", @"brother",
              @"cafes", @"cafe",
              @"children", @"child",
              @"corpuses", @"corpus",
              @"cows", @"cow",
              @"ganglions", @"ganglion",
              @"genies", @"genie",
              @"genera", @"genus",
              @"graffiti", @"graffito",
              @"hoofs", @"hoof",
              @"loaves", @"loaf",
              @"men", @"man",
              @"monies", @"money",
              @"mongooses", @"mongoose",
              @"moves", @"move",
              @"mythoi",@"mythos",
              @"niches", @"niche",
              @"numina", @"numen",
              @"occiputs", @"occiput",
              @"octopuses", @"octopus",
              @"opuses", @"opus",
              @"oxen", @"ox",
              @"penises", @"penis",
              @"people", @"person",
              @"sexes", @"sex",
              @"soliloquies", @"soliloquy",
              @"testes", @"testis",
              @"trilbys", @"trilby",
              @"turfs", @"turf",
              nil],@"irregular",
             nil];
    }
    
    return d;
}
/**
 * Returns the given camelCasedWord as an underscored_word.
 */
+(NSString *)underscoreCamelCaseWord:(NSString *)word{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?<=\\w)([A-Z])" options:0 error:&error];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:word options:0 range:NSMakeRange(0, [word length]) withTemplate:@"_$1"];
    return [modifiedString lowercaseString];
}
/**
 * Return word in plural form.
 */
+(NSString *)pluralizeWord:(NSString *)word{
    NSError *error = NULL;
    // Check Uninflected
    NSString *uninflectedRule = [NSString stringWithFormat:@"^((?:%@))$", [[[HOTInflector _plural] objectForKey:@"uninflected"] componentsJoinedByString:@"|"]];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:uninflectedRule options:NSRegularExpressionCaseInsensitive error:&error];
    if([regex numberOfMatchesInString:word options:0 range:NSMakeRange(0, [word length])]){
        return word;
    }
    // Check irregular words
    NSString *irregularRule = [NSString stringWithFormat:@"^((?:%@))$", [[[[HOTInflector _plural] objectForKey:@"irregular"] allKeys] componentsJoinedByString:@"|"]];
    regex = [NSRegularExpression regularExpressionWithPattern:irregularRule options:NSRegularExpressionCaseInsensitive error:&error];
    if([regex numberOfMatchesInString:word options:0 range:NSMakeRange(0, [word length])]){
        return [[[HOTInflector _plural] objectForKey:@"irregular"] objectForKey:word];
    }
    // Check rules
    for(NSArray *ruleAr in [[HOTInflector _plural] objectForKey:@"rules"] ){
        NSString *rule = [ruleAr objectAtIndex:1];
        NSString *replacement = [ruleAr objectAtIndex:0];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:rule options:NSRegularExpressionCaseInsensitive error:&error];
        
        if([regex numberOfMatchesInString:word options:0 range:NSMakeRange(0, [word length])]){
            return [regex stringByReplacingMatchesInString:word options:0 range:NSMakeRange(0, [word length]) withTemplate:replacement];
            
        }
    }
    return word;
}

/**
 * Returns corresponding table name for given model $className. ("people" for the model class "Person").
 */
+(NSString *)tableize:(NSString *)className{
    // Inflector::pluralize(Inflector::underscore($className))
    return [HOTInflector pluralizeWord:[HOTInflector underscoreCamelCaseWord:className]];
}

@end
