#import <Foundation/Foundation.h>

extern NSString * const SCNotifyModelOfButtonChange;
extern NSString * const SCNotifyModelOfParameterChange;


@interface SimParameter : NSObject <NSCopying>
{
    NSString * name;
    double value;
    double defaultValue;        /* The value the user originally set. */
    double maxValue;
    double minValue;
    BOOL doShow;                /* used for parameters with separate UI controls */
}
@property (copy) NSString *name;
//@property (assign) double value;
@property (assign) double defaultValue;
@property (assign) double maxValue;
@property (assign) double minValue;
@property (assign) BOOL doShow;

-(double) value;
-(void) initValue:(double)value;
-(void) setValue:(double)value;
-(void) setValueNoBroadcast:(double)value;
-(BOOL) isEqual:(id)sim_parameter;
-(NSUInteger) hash;
-(NSDictionary*) asPropertyListDictionary;
-(void) fromPropertyListDictonary:(NSDictionary*) sim_parameter_dict;

-(void) broadcastValue;

@end


@interface SimButton : NSObject <NSCopying>
{
    NSString * name;
    NSString * onLabel;
    NSString * offLabel;
    BOOL value;
    BOOL defaultValue;          /* The value the user originally set. */
    BOOL doShow;                /* used for buttons with separate UI controls */
}
@property (copy) NSString *name;
@property (copy) NSString *onLabel;
@property (copy) NSString *offLabel;
//@property (assign) BOOL value;
@property (assign) BOOL defaultValue;
@property (assign) BOOL doShow;

-(BOOL) value;
-(void) setValue:(BOOL)value;
-(void) setValueNoBroadcast:(BOOL)value;
-(void) initValue:(BOOL)value; // no callback to button action.


-(BOOL) isEqual:(id)sim_button;
-(NSUInteger) hash;

-(NSDictionary*) asPropertyListDictionary;
-(void) fromPropertyListDictonary:(NSDictionary*) sim_button_dict;

-(void) broadcastValue;

@end
