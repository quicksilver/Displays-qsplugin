

#import <Foundation/Foundation.h>

#import <QSCore/QSObjectSource.h>
@interface QSDisplaysActionProvider : NSObject {

}

- (NSURL *) getRemoteFile:(NSURL *)fileURL;

@end

@interface QSDisplaysObjectSource : QSObjectSource {
    
}

@end
