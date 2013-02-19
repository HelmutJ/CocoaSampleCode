-- //     File: TaskListAppDelegate.applescript
-- // Abstract: n/a
-- //  Version: 1.0
-- // 
-- // Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
-- // Inc. ("Apple") in consideration of your agreement to the following
-- // terms, and your use, installation, modification or redistribution of
-- // this Apple software constitutes acceptance of these terms.  If you do
-- // not agree with these terms, please do not use, install, modify or
-- // redistribute this Apple software.
-- // 
-- // In consideration of your agreement to abide by the following terms, and
-- // subject to these terms, Apple grants you a personal, non-exclusive
-- // license, under Apple's copyrights in this original Apple software (the
-- // "Apple Software"), to use, reproduce, modify and redistribute the Apple
-- // Software, with or without modifications, in source and/or binary forms;
-- // provided that if you redistribute the Apple Software in its entirety and
-- // without modifications, you must retain this notice and the following
-- // text and disclaimers in all such redistributions of the Apple Software.
-- // Neither the name, trademarks, service marks or logos of Apple Inc. may
-- // be used to endorse or promote products derived from the Apple Software
-- // without specific prior written permission from Apple.  Except as
-- // expressly stated in this notice, no other rights or licenses, express or
-- // implied, are granted by Apple herein, including but not limited to any
-- // patent rights that may be infringed by your derivative works or by other
-- // works in which the Apple Software may be incorporated.
-- // 
-- // The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
-- // MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
-- // THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
-- // FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
-- // OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
-- // 
-- // IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
-- // OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- // SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- // INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
-- // MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
-- // AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
-- // STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
-- // POSSIBILITY OF SUCH DAMAGE.
-- // 
-- // Copyright (C) 2009 Apple Inc. All Rights Reserved.
-- // 

script Task_ListAppDelegate
	property tableData : {}
	property tableDataController : missing value
	property CalCalendarStore : class "CalCalendarStore"
	property NSMutableArray : class "NSMutableArray"
	property CalTaskClass : class "CalTask"
	property NSNotificationCenter : class "NSNotificationCenter"
	
	on awakeFromNib()
		set tableData to NSMutableArray's array()
		loadInitialData()
		
		-- This notification lets us watch for external changes to the list of Todo items.
		tell NSNotificationCenter's defaultCenter() to addObserver_selector_name_object_(me, "eventsChangedExternally:", my CalTasksChangedExternallyNotification, CalCalendarStore's defaultCalendarStore)
		
		-- Observe the tableData to-many property itself so we can watch for the the user adding or removing Todo items.
		tell me to addObserver_forKeyPath_options_context_(me, "tableData", (my NSKeyValueObservingOptionNew as integer) + (my NSKeyValueObservingOptionOld as integer), missing value)
	end awakeFromNib
	
	on eventsChangedExternally_(notification)
		-- Todo items have been changed in another application, such as Mail or iCal. Check for deleted, inserted, and updated Todo items.
		set deletedRecordUUIDs to notification's userInfo's objectForKey_(my CalDeletedRecordsKey)
		if deletedRecordUUIDs is not missing value then
			repeat with calTask in tableData
				if deletedRecordUUIDs's containsObject_(calTask's uid) then
					tableDataController's removeObject_(calTask)
				end if
			end repeat
		end if
		
		set insertedRecordUUIDs to notification's userInfo's objectForKey_(my CalInsertedRecordsKey)
		if insertedRecordUUIDs is not missing value then
			repeat with insertedRecordUUID in insertedRecordUUIDs
				set newfoundTask to CalCalendarStore's defaultCalendarStore's taskWithUID_(insertedRecordUUID)
				loadNewTaskFromCalStore(newfoundTask)
			end repeat
		end if
		
		set updatedRecordUUIDs to notification's userInfo's objectForKey_(my CalUpdatedRecordsKey)
		if updatedRecordUUIDs is not missing value then
			repeat with calTask in tableData
				if updatedRecordUUIDs's containsObject_(calTask's uid) then
					-- Update the record. Get a new object, then use its data to update the existing one in the array.
					set newfoundTask to CalCalendarStore's defaultCalendarStore's taskWithUID_(calTask's uid)
					tell calTask
						set its title to newfoundTask's title
						set its priority to newfoundTask's priority
					end tell
				end if
			end repeat
		end if
	end eventsChangedExternally_
	
	on windowWillClose_(notification)
		-- When the window closes, we want to quit the application.
		tell my NSApp to terminate_(me)
	end windowWillClose_
	
	on addTask_(sender)
		set newTask to CalTaskClass's task()
		set newTask's calendar to (first item of CalCalendarStore's defaultCalendarStore's calendars)
		set newTask's title to "New Task"
		loadNewTaskFromCalStore(newTask)
	end addTask_
	
	on removeTask_(sender)
		-- Tell the array controller to remove its current selection.
		tableDataController's remove_(me)
	end removeTask_
	
	on loadNewTaskFromCalStore(newTask)
		-- Add to the list, and observe the properties we care about so we can explicitly save them to CalStore when the user changes them.
		tell tableDataController to addObject_(newTask)
		tell newTask to addObserver_forKeyPath_options_context_(me, "title", my NSKeyValueObservingOptionNew, missing value)
		tell newTask to addObserver_forKeyPath_options_context_(me, "priority", my NSKeyValueObservingOptionNew, missing value)
	end loadNewTaskFromCalStore
	
	on loadInitialData()
		-- Load all Todo items from CalStore.
		set calendarStore to CalCalendarStore's defaultCalendarStore
		set theCalendars to calendarStore's calendars
		set todoPredicate to CalCalendarStore's taskPredicateWithCalendars_(theCalendars)
		set tasksInCalStore to CalCalendarStore's defaultCalendarStore's tasksWithPredicate_(todoPredicate)
		repeat with taskInCalStore in tasksInCalStore
			loadNewTaskFromCalStore(taskInCalStore)
		end repeat
	end loadInitialData
	
	on saveTask(aTask)
		-- Todo items need to be explicitly saved to CalStore for changes to take effect.
		tell CalCalendarStore's defaultCalendarStore to saveTask_error_(aTask, reference)
		set saveResult to the result
		if not item 1 of the saveResult then
			-- If there is an error, it will be item 2 in this list.
			set err to item 2 of saveResult
			-- We got an error, but we want to try and continue saving the other tasks.
			log "Error saving task: " & (err's localizedDescription() as text)
		else
			-- The save went well.
		end if
	end saveTask
	
	on observeValueForKeyPath_ofObject_change_context_(keyPath, object, changeDictionary, aContext)
		if (keyPath as text) is equal to "tableData" then
			set theChange to changeDictionary's objectForKey_(my NSKeyValueChangeKindKey) as integer
			if theChange is equal to my NSKeyValueChangeRemoval then
				-- Todo items removed in the UI. Remove them from CalStore.
				set oldArray to changeDictionary's objectForKey_(my NSKeyValueChangeOldKey)
				repeat with taskToRemove in oldArray
					try
						-- This may fail if we're getting rid of an externally removed task, so ignore this error.
						tell CalCalendarStore's defaultCalendarStore to removeTask_error_(taskToRemove, reference)
					end try
				end repeat
			else if theChange is equal to my NSKeyValueChangeInsertion then
				-- Todo items added to the UI. Add them to CalStore.
				set indexesToInsert to changeDictionary's objectForKey_(my NSKeyValueChangeIndexesKey)
				set tasksToInsert to tableData's objectsAtIndexes_(indexesToInsert)
				repeat with taskToInsert in tasksToInsert
					saveTask(taskToInsert)
				end repeat
			end if
		else
			-- The user has updated a Todo item in the UI. Save it to CalStore immediately.
			saveTask(object)
		end if
	end observeValueForKeyPath_ofObject_change_context_
end script