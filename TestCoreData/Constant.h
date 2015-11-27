//
//  Constant.h
//  TestCoreData
//
//  Created by bobozhu on 15/11/24.
//  Copyright © 2015年 bobozhu. All rights reserved.
//

#ifndef Constant_h
#define Constant_h
#define    DEBUG_ENABLE
#ifdef DEBUG_ENABLE
#define BBINFO(fmt, ...)          NSLog(@"[%@:%d]"fmt, \
[[NSString stringWithFormat:@"%s", __FILE__] lastPathComponent], \
__LINE__, \
##__VA_ARGS__)
#define BBDEALLOC() NSLog(@"*******dealloc%@: %@*****", NSStringFromSelector(_cmd), self);
#define BBLOG() NSLog(@"%s, %d",__PRETTY_FUNCTION__, __LINE__)
#else
#define BBINFO(fmt, ...) ((void)0)
#define BBDEALLOC() ((void)0)
#define BBLOG() ((void)0)
#endif
#define BEGIN_TRANSACTION	@"BEGIN TRANSACTION;"
#define COMMIT_TRANSACTION	@"COMMIT TRANSACTION;"
#define END_TRANSACTION		@"END TRANSACTION;"
#define ROOLBACK_TRANSACTION @"ROLLBACK TRANSACTION;"

#endif /* Constant_h */
