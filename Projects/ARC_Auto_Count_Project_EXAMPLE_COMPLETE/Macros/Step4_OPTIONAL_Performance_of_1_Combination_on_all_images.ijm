// 5/22/2023 - Optimize parameters by comparing the autocount for each combination to a manual count.

// NOTES FOR THE COMPLETED EXAMPLE:
// The "best" combination (lowest average absolute difference in accuracy, aka "Avg Acc Dif") of my limited example options was
// PROCESSING METHOD: Gamma
// THRESHOLD: MaxEntropy
// LOWER HUE DISPLAY LIMIT: 58
// UPPER HUE DISPLAY LIMIT: 113
// PIXEL SIZE: 100
// This combination appears on row 14 of my Optimization_Avgs.csv file in the TrainSet/3_MergeGamma/Best_Parameter_Combinations/ folder,
// in the sense that the csv file, when opened in Microsoft Excel, has the row number "14" highlighted when I click on it,
// and the column labels appear in row number "1." HOWEVER, this code requires the first row (with the column labels) to
// be considered row "0," meaning that the best combination truly appeared in "row 13." The variable "c" needs to be set to
// this true row number minus 2, or 13 - 2 = 11.

////////////////////


// PURPOSE:
// Optional - The macro, "20230522_Step2_Optimizing_All_Parameters_Train.ijm" has its own Steps 1, 2, & 3.
// Step 3 yields metrics that are averaged across all "subjects" (images) in the Train set, but if you want to see what
// the individual scores were for each subject (image) for a given combination (like the best combination), run this macro.
// (Example: Run Combination 1, see that the first image had 2 misses, but the second had 14, meaning the combination
// was not performing equally well across all images. Etc.)

// IMPORTANT NOTES FOR SETUP:
// 1. Identify which processing method was used in the combination of interest, and update the folder path to point to
//    that folder (e.g. "3_MergeRaw").
// 2. Open the "Optimizations" subfolder in the appropriate processing method folder (e.g. "3_MergeRaw"). Open one of the
//    csv files for one of the subjects (images). Locate the row that holds information about the combination of interest.
//    What number represents that row in the csv file, if the very first row is "0" and the second row is "1" and so on?
//    Subtract 2 from that number and update the code (exact line excerpt below) to reflect that new number:
//    c = 1608; // THIS IS THE ROW OF YOUR COMBINATION MINUS 2, BUT MAKE SURE THE FIRST ROW IS "0" AND THE SECOND ROW IS "1," ETC
// 3. This code requires one csv file to be made ahead of time and stored in the "Best_Parameter_Combinations" subfolder of the
//    processing method folder. The file should be named "Combination_"+c+"_Subject_Stats.csv" where "c" is the number identified
//    in point 2, above, representing the row of the parameter combination (minus 2).


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////////////////////////////////////////////////////////
////// Optional - View a Combination's evaluation metrics on subjects aka images individually ///////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


// FOR ONE PARAMETER COMBINATION, COMPILE STATS FROM ALL SUBJECTS

// For one combination, look at every subject's output for that combination
	// Open an individual subject's table of parameter combinations and identify the row that matches the combination in question
	// Save the accuracy, abs dif in acc, number of errors, and error rate for this subject to growing arrays.
// After looping through all subjects, paste each subject's metrics into a single table for easy viewing


//////////// IMPORTANT TASK!!!!!! /////////
// YOU NEED TO create this one excel doc ahead of time: 
// open(merge_folder+best_folder+"Combination_"+c+"_Subject_Stats.csv");
///////////////////////////////////////////


// UPDATE this to the appropriate processing method folder
merge_folder = "D:/Projects/ARC_Auto_Count_Project_EXAMPLE_COMPLETE/TrainSet/3_MergeGamma/";
optimization_folder = "Optimizations/";
// New folder for holding the most important excel file which aggregates the parameter info across all subjects.
best_folder = "Best_Parameter_Combinations/";


setBatchMode(true);


function append(arr, value) {
	arr2 = newArray(arr.length+1);
     
    for (i=0; i<arr.length; i++) {
		arr2[i] = arr[i];
	}
   	arr2[arr.length] = value;

    return arr2;
}

files = getFileList(merge_folder+optimization_folder);

c = 11; // THIS IS THE ROW OF YOUR COMBINATION MINUS 2, BUT MAKE SURE THE FIRST ROW IS "0" AND THE SECOND ROW IS "1," ETC

subject_id = newArray;
manual_count = newArray;
auto_count = newArray;
errors = newArray;
error_rate = newArray;
avg = newArray;
avg_dif = newArray;

for (f=0; f < files.length; f++) {
	if (endsWith(files[f], ".csv")) {
		open(merge_folder+optimization_folder+files[f]);
		
 		subject = substring(files[f],0,lengthOf(files[f])-6); // grab id without "_M.tif" at end
		subject_id = append(subject_id, subject);
		man = Table.get("Manual Count", c);		
		manual_count = append(manual_count, man);
		auto = Table.get("Auto Count", c);
		auto_count = append(auto_count, auto);
		errors = append(errors, Table.get("Errors", c));
		error_rate = append(error_rate, Table.get("Errors per MC", c));

		thresh = Table.getString("Threshold", c);
		lower_hue = Table.get("Lower Hue", c);
		upper_hue = Table.get("Upper Hue", c);
		cell_pixel_size = Table.get("Pixel Size", c);

		acc = auto/man;
		acc_dif = 1-acc;
		abs_acc_dif = abs(acc_dif);

		avg = append(avg, acc);
		avg_dif = append(avg_dif, abs_acc_dif);

		selectWindow(files[f]);
		run("Close");

	}
} // End of looping through subjects to build arrays for this parameter combination.


open(merge_folder+best_folder+"Combination_"+c+"_Subject_Stats.csv");

for (f=0; f < files.length; f++) {
	Table.set("ID", f, subject_id[f]);
	Table.set("Manual Count", f, manual_count[f]);
	Table.set("Autocount", f, auto_count[f]);
	Table.set("Acc", f, avg[f]);
	Table.set("Acc Dif", f, avg_dif[f]);
	Table.set("Errors", f, errors[f]);
	Table.set("Error Rate", f, error_rate[f]);

	Table.set("Threshold", f, thresh);
	Table.set("Lower Hue", f, lower_hue);
	Table.set("Upper Hue", f, upper_hue);
	Table.set("Pixel Size", f, cell_pixel_size);

	Table.update;
	saveAs("Results", merge_folder+best_folder+"Combination_"+c+"_Subject_Stats.csv");

	//selectWindow("Results");
	//run("Close");
} // End of looping through all subjects' stats

setBatchMode(false);





