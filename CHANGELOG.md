## 1.0.15
Fixed 'full' bool issue

## 1.0.14
Corrected delete & path issue
Added Geo queries
Added ability to add login oAuth data

## 1.0.13
Added full bool to convert objects to JSON correctly

## 1.0.12
Fixed logout

## 1.0.11
ParseFile fixed
Anonymous login
SecurityContext
CloudFunctions with objects

## 1.0.10
Add ParseConfig.
Fixed whereEqualsTo('', PARSEOBJECT) and other queries

## 1.0.9
Fixed Health Check issue

## 1.0.8
Fixed some queries

## 1.0.7

Some items now return a response rather than a ParseObject

## 1.0.6

BREAK FIX - Fixed ParseUser return type so now returns ParseResponse
BREAK FIX - Changed query names to make more human readable
Fixed pinning and unpinning

## 1.0.5

Corrected save. Now formatted items correctly for saving on server

## 1.0.4

Bug fix for get all items
Can now pin/unpin/fromPin for all ParseObjects
Now supports generics
Cody tidy around extending

## 1.0.3

Added persistent storage. When a logged in user closes the app, then reopens, the data
will now be persistent. Best practice would be to Parse.init, then Parse.currentUser. This
will return the current user session and allow auto login. Can also pin data in storage.

## 1.0.2

Fixed login

## 1.0.1

Added documentation and GeoPoints

## 1.0.0

First full release!

## 0.0.4

Added description

## 0.0.3

Added more cloud functions
