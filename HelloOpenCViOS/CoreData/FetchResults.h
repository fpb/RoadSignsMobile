//
//  FetchResults.h
//  HelloOpenCViOS
//
//  Created by David on 14/05/13.
//  Copyright (c) 2013 FCT/UNL. All rights reserved.
//

#pragma once

#import <CoreData/CoreData.h>

NSArray* FetchResultsFromEntitywithPredicate(NSManagedObjectContext *managedObjectContext,
											 NSString *entityName,
											 NSPredicate *predicate,
											 NSArray *sortDescriptors);

NSArray* FetchResultsFromEntitywithPredicate(NSManagedObjectContext *managedObjectContext,
											 NSString *entityName,
											 NSPredicate *predicate,
											 NSArray *sortDescriptors)
{
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext]];
	[request setPredicate:predicate];
	if (sortDescriptors)
		[request setSortDescriptors:sortDescriptors];
	
	return [managedObjectContext executeFetchRequest:request error:nil];
}