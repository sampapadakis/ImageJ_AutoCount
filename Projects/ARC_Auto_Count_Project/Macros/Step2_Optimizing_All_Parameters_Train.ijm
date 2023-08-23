// 5/22/2023 - Optimize parameters by comparing the autocount for each combination to a manual count.

// This macro involves 3 Steps:
// 1. Take the raw images and process them in 3 ways, saving those images into 3 respective folders (total of 4 folders of images).
// 2. Run thresholding and autocounting parameters on the images in one of the 4 processing folders (e.g. 3_MergeRaw).
// 3. Calculate and save the evaluation metrics (hits, misses, accuracy, error, etc.) averaged across all images in the folder.
//
// * Repeat steps 2 & 3 on the other processing folders sequentially (e.g. Minimum, Gamma, and then GMA images).
// * User must manually paste the rows from all 4 output csv files (from Step 3) into a single spreadsheet.
// * User must manually sort the compiled output csv file to find the combination with the greatest accuracy (smallest Avg Acc Dif).

// IMPORTANT NOTES FOR SETUP:
// 1. Run this macro on the TRAIN image set after manual cell counting and marker placement is completed.
// 2. Ensure the Train set of images are stored in a separate folder from the Test set.
// 3. Update the folder paths if needed. The two types of inputs to this code are merged images and cell markers.
//    These should be stored in the following two folders, respectively (update the paths if needed):
//    "D:/Projects/ARC_Auto_Count_Project/TrainSet/3_MergeRaw/"
//    "D:/Projects/ARC_Auto_Count_Project/TrainSet/1_Markers/"
//    The filenames for the markers should start with the entire image filename, before the "_M" (aka the "subject_id" variable).
// 4. There are a total of 4 processing methods. Each gets its own section (e.g. "RAW," "GAMMA," "MINIMUM," "GMA") in the
//    code below (Steps 2 & 3), and each gets its own folder to store images that have been processed with that method (Step 1).
//    For example, "Raw" images, which undergo no further processing, are already stored in the subfolder, "3_MergeRaw."
//    Feel free to run each section separately (highlight the text and run just the selection), as well as add new processing
//    methods, making sure to create a new folder. The new processing code could be added to "Step 1," and any of the sections for
//    Steps 2 & 3 (e.g. "RAW") could be copied to run the optimization - just update the folder path to point to your new folder.
// 5. Running the optimization section (Steps 2 & 3) requires several csv files to be made ahead of time. For Step 2 (aka "PART 1"),
//    one csv file PER IMAGE must be stored in the "Optimizations" subfolder nested within EACH processing folder (e.g. "3_MergeRaw").
//    This file should be named "Optimization_Comparison_"+subject_id+".csv" where subject_id is the entire image filename except for
//    the "_M" ending. The first cell in each csv file should contain the following text: ID
//    For Step 3 (aka "PART 2"), create one csv file PER PROCESSING FOLDER to be stored in each folder's nested "Best_Parameter_Combinations"
//    subfolder. This file should be named "Optimization_Avgs.csv" and have the following text in the first cell: Avg Acc
// 6. The optimization parameters are hardcoded in EACH processing section below (under "Steps 2 & 3," under each processing section
//    like "RAW," under each "PART 1," at the top of the initial set of for loops AND lower down at the "ANALYZE PARTICLES" for loop).
//    Manually adjust these to explore more parameter options. The settings that are currently hardcoded are as follows:
//    THRESHOLDING ALGORITHMS:
//    thresholds = newArray("MaxEntropy", "Moments", "Otsu", "Triangle", "Intermodes") // 5 options
//    HUE DISPLAY LIMITS:
//    (lower_hue = 50; lower_hue < 75; lower_hue=lower_hue+6) { // 5 options, range of 50-74, up by 6's
//    (upper_hue = 109; upper_hue < 114; upper_hue=upper_hue+2) { // 3 options, range of 109-113, up by 2's
//    PIXEL SIZE DURING ANALYZE PARTICLES
//    (cell_pixel_size = 40; cell_pixel_size < 281; cell_pixel_size = cell_pixel_size + 10) { // 25 options, range of 40-280, up by 10's
// 7. If the number of optimization parameter options have changed from those stated in point 6, then a different number of parameter
//    combinations will be produced. This number is used in Step 3 (aka "PART 2") and would need to be updated if the parameter options
//    have changed. The number of combinations is # thresholds * # lower hues * # upper hues * # pixel size options. Adjust these lines:
//    for (c=0; c<1875; c++) { //NUMBER OF COMBINATIONS: 5 thresh * 5 lower hue * 3 upper hue * 25 pixel sizes = 1875.
// 8. If errors are encountered in the "PART 2" sections, some potential solutions are documented as comments under the "RAW" section.
// 9. If you encounter problems, try running each section separately (highlight the text and run just that selection).

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////
////// Step 1. PROCESSING //////
////////////////////////////////

// Create folders for each processing method, like "3_MergeMinimum," "3_MergeGamma," and "3_MergeGMA."

setBatchMode(true);

proj_folder = "D:/Projects/ARC_Auto_Count_Project/TrainSet/";
files = getFileList(proj_folder+"3_MergeRaw/");

for (i=0; i < files.length; i++) {

	if (endsWith(files[i], ".tif")) {
	
		open(proj_folder+"3_MergeRaw/"+files[i]);
		run("Minimum...", "radius=5");
		saveAs("Tiff", proj_folder+"3_MergeMinimum/"+files[i]);
		close();

		open(proj_folder+"3_MergeRaw/"+files[i]);
		run("Duplicate...", "title=Dup");
		selectWindow(files[i]);	
		run("Gamma...", "value=0.50");
		saveAs("Tiff", proj_folder+"3_MergeGamma/"+files[i]);

		run("Minimum...", "radius=5");
		imageCalculator("Average create", "Dup", files[i]);
		selectWindow("Result of Dup");
		saveAs("Tiff", proj_folder+"3_MergeGMA/"+files[i]);
		close();
		close();
		close();
	}
}

setBatchMode(false);




////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////
////// Steps 2 & 3. THRESHOLDING, AUTOCOUNT, AND EVALUATION METRICS //////
//////////////////////////////////////////////////////////////////////////

// PURPOSE:

// PART 1.
// For each image in your folder,
	// loop through different threshold algorithms.
	// For each threshold method,
		// Loop through different hue display parameters (low and high);
		// For each low-high hue combo,
			// create a binary image using the current threshold algorithm.
			// For each binary image created (won't be saved, though),
				// loop the binary through a series of different pixel sizes for object identification.
					// Compare the auto count to the manual count and save the comparisons.
// Move on to the next image and loop through all of the parameter combinations again.

// PART 2.
// After all combinations have been run on all images, loop through the comparison csv files to find the best combination across all images.

// RAW has some comments in part 2 regarding alternative pieces of code to try if errors are encountered.



/////////////////// RAW ////////////////////


///////////////////////////////////
///////////// PART 1 //////////////
///////////////////////////////////

//////////// IMPORTANT TASK!!!!!! /////////
// YOU NEED to create these excel sheets ahead of time, one per main merged image:
// merge_folder+optimization_folder+"Optimization_Comparison_"+subject_id+".csv"
// where subject ID is the entire filename except for the "_M" ending.
// Create at least this empty column name in each file; other columns will be added automatically:
// ID
///////////////////////////////////////////


//// SETUP ////

// Main merged files to be automatically counted are here:
merge_folder = "D:/Projects/ARC_Auto_Count_Project/TrainSet/3_MergeRaw/";

// Can only compare to one set of manual counts. Edit folder path appropriately.
// Manual count markers are here:
manual_count_folder = "D:/Projects/ARC_Auto_Count_Project/TrainSet/1_Markers/";

// Save count comparison csv files here, nested under the 3_Merge folder:
optimization_folder = "Optimizations/";

// For trying different thresholds:
thresholds = newArray("MaxEntropy", "Moments", "Otsu", "Triangle", "Intermodes");

// Create a function to append values to a growing array.
function append(arr, value) {
	arr2 = newArray(arr.length+1);
     
    for (i=0; i<arr.length; i++) {
		arr2[i] = arr[i];
	}
   	arr2[arr.length] = value;

    return arr2;
}

best_parameters = newArray;
best_subj = newArray;

setBatchMode(true);

marker_list = getFileList(manual_count_folder);
files = getFileList(merge_folder);

for (f=0; f < files.length; f++) {
	if (endsWith(files[f], ".tif")) {
		// SET THE PARAMETERS TO LOOP THROUGH: THRESHOLD, LOWER HUE LIMIT, UPPER HUE LIMIT
		for (t=0; t < thresholds.length; t++){
			for (lower_hue = 50; lower_hue < 75; lower_hue=lower_hue+6) { // 5 options, range of 50-74, up by 6's
				for (upper_hue = 109; upper_hue < 114; upper_hue=upper_hue+2) { // 3 options, range of 109-113, up by 2's

						
///////////////////////////////////////////////////////////////
					// THRESHOLD WITH HUE PARAMETERS
					open(merge_folder+files[f]);
					run("Color Threshold...");
					min=newArray(3);
					max=newArray(3);
					filter=newArray(3);
					a=getTitle();
					run("HSB Stack");
					run("Convert Stack to Images");
					selectWindow("Hue");
					rename("0");
					selectWindow("Saturation");
					rename("1");
					selectWindow("Brightness");
					rename("2");
					min[0]=lower_hue; // Looping through lower values
					max[0]=upper_hue; // Looping through upper values
					filter[0]="pass";
					min[1]=0;
					max[1]=255;
					filter[1]="pass";

					for (i=0;i<2;i++){
						selectWindow(""+i);
						setThreshold(min[i], max[i]);
						run("Convert to Mask");
						if (filter[i]=="stop")  run("Invert");
					}
					imageCalculator("AND create", "0","1");

					selectWindow("2");
					setAutoThreshold(thresholds[t]+" dark"); // Loops through the different thresholds
					setOption("BlackBackground", false);
					run("Convert to Mask");
	
					imageCalculator("AND create", "Result of 0","2");
					for (i=0;i<3;i++){
						selectWindow(""+i);
						close();
					}
					selectWindow("Result of 0");
					close();
	
					selectWindow("Result of Result of 0");
					//run("8-bit");
					// NO USE SAVING THIS THRESHOLDED BINARY IMAGE; THERE WILL BE FAR TOO MANY, AND IMPOSSIBLE TO SAVE THEM IN DIF FOLDERS.
						// saveAs("Tiff", full_folder+files[j]);
						//close();


////////////////////////////////////////////////////////////////////
					// ANALYZE PARTICLES
					
					// SET THE PIXEL SIZE PARAMETER TO LOOP THROUGH
					for (cell_pixel_size = 40; cell_pixel_size < 281; cell_pixel_size = cell_pixel_size + 10) { // 25 options, range of 40-280, up by 10's
						selectWindow("Result of Result of 0");
						run("Analyze Particles...", "size="+cell_pixel_size+"-Infinity pixel show=Outlines exclude add");
						selectWindow("Drawing of Result of Result of 0");
						nROIs = roiManager("count"); // number of objects

						// Make objects bigger to ensure a marker overlaps it
						for (j=0; j < nROIs; j++) {
							roiManager("Select", 0);
							run("Enlarge...", "enlarge=8 pixel");
							roiManager("Add");
							roiManager("Select", 0);
							roiManager("Delete");
						}

						// Fill the particle objects to give the markers a background
						run("Color Picker...");
						setForegroundColor(124, 124, 124); //gray

						for (j=0; j < nROIs; j++) {
							roiManager("Select", j);
							roiManager("Fill");
						}

						// Now to open the markers
						subject_id = substring(files[f],0,lengthOf(files[f])-6); // grab id without "_M" at end
										
						for (e=0; e < marker_list.length; e++) {
							if (endsWith(marker_list[e], ".roi")) {
								if (startsWith(marker_list[e], subject_id)) {
									marker_roi = marker_list[e];
								}
							}
						}
											
						roiManager("Open", manual_count_folder+marker_roi);
						roiManager("Select", nROIs);
						roiManager("Measure");

						markers = Table.size;
						counter_hits = 0;

						for (j=0; j < Table.size; j++) {
							if (Table.get("Mean", j) < 125) { // if the bg is 124 gray (an object) or less, as opposed to 255 white--no object,
								counter_hits++; //mark it as a hit
							}
						}

						selectWindow("Results");
						run("Close");
						
						// Calculate some comparisons between auto and manual count
						
						misses = markers - counter_hits;
						fp = nROIs - counter_hits;
						diff = markers-nROIs;
						abs_diff = abs(diff);
						acc = nROIs/markers;
						acc_dif = 1-acc;
						abs_acc_dif = abs(acc_dif);
						errors = fp + misses;
						error_rate = errors/markers;
						
						// Open a tracking table (csv) and add onto it:										
						open(merge_folder+optimization_folder+"Optimization_Comparison_"+subject_id+"_M.csv");

						Table.set("ID", Table.size, subject_id); // the .size as the index adds a new row
						Table.set("Hits", Table.size-1, counter_hits); // don't want another new row; just add to the previously-made one
						Table.set("Misses", Table.size-1, markers - counter_hits);
						Table.set("False Positives", Table.size-1, nROIs - counter_hits);
						Table.set("Manual Count", Table.size-1, markers);
						Table.set("Auto Count", Table.size-1, nROIs);
						Table.set("Difference", Table.size-1, diff);
						Table.set("Absolute Difference", Table.size-1, abs_diff);
						Table.set("Accuracy", Table.size-1, acc);
						Table.set("Absolute Difference in Accuracy", Table.size-1, abs_acc_dif);
						Table.set("Errors", Table.size-1, errors);
						Table.set("Errors per MC", Table.size-1, error_rate);
						Table.set("Threshold", Table.size-1, thresholds[t]);
						Table.set("Lower Hue", Table.size-1, lower_hue);
						Table.set("Upper Hue", Table.size-1, upper_hue);
						Table.set("Pixel Size", Table.size-1, cell_pixel_size);
						Table.update;
						
						saveAs("Results", merge_folder+optimization_folder+"Optimization_Comparison_"+subject_id+"_M.csv");
						
						selectWindow("Drawing of Result of Result of 0");
						close();
						roiManager("Deselect");
						roiManager("Delete");
						//selectWindow("Results");
						//run("Close");
					} // End pixel size loop
					selectWindow("Result of Result of 0");
					close();
				} // End upper hue limit loop
			} // End lower hue limit loop
		} // End threshold method loop
	} // End work on the image file, if ends with ".tif"
} // End working on all files in the folder list.


///////////////////////////////////////////////////////////////////////


///////////////////////////////////
///////////// PART 2 //////////////
///////////////////////////////////

// FIND BEST PARAMETER ACROSS ALL SUBJECTS, BASED ON AVERAGE ACCURACY AND ERROR ACROSS SUBJECTS

// For one combination, look at every subject's output for that combination
	// Open an individual subject's table of parameter combinations and identify the row that matches the combination in question
	// Save the accuracy, abs dif in acc, number of errors, and error rate for this subject to growing arrays.
// After looping through all subjects, find the mean of those accuracy and error arrays for that combination.
// Save the avgs to a new table that will grow and eventually be as long as the # of combinations.

// Duplicated from Part 1, in case you want to reference the paths again:
merge_folder = "D:/Projects/ARC_Auto_Count_Project/TrainSet/3_MergeRaw/";
optimization_folder = "Optimizations/";
// New folder for holding the most important excel file which aggregates the parameter info across all subjects.
best_folder = "Best_Parameter_Combinations/";

//////////// IMPORTANT TASK!!!!!! /////////
// YOU NEED TO create this one excel doc ahead of time: 
// merge_folder+best_folder+"Optimization_Avgs.csv"
// Create at least this empty column name; others will be added automatically:
// Avg Acc
///////////////////////////////////////////

// Duplicated function from above
function append(arr, value) {
	arr2 = newArray(arr.length+1);
     
    for (i=0; i<arr.length; i++) {
		arr2[i] = arr[i];
	}
   	arr2[arr.length] = value;

    return arr2;
}

files = getFileList(merge_folder+optimization_folder);
for (c=0; c<1875; c++) { //NUMBER OF COMBINATIONS: 5 thresh * 5 lower hue * 3 upper hue * 25 pixel sizes = 1875.
	avg = newArray;
	avg_dif = newArray;
	errors = newArray;
	error_rate = newArray;

	for (f=0; f < files.length; f++) {
		if (endsWith(files[f], ".csv")) {
			open(merge_folder+optimization_folder+files[f]);

			manual_count = Table.get("Manual Count", c);
			auto_count = Table.get("Auto Count", c);
			errors = append(errors, Table.get("Errors", c));
			error_rate = append(error_rate, Table.get("Errors per MC", c));

			thresh = Table.getString("Threshold", c); // could also try Table.get() if .getString causes issue
			lower_hue = Table.get("Lower Hue", c);
			upper_hue = Table.get("Upper Hue", c);
			cell_pixel_size = Table.get("Pixel Size", c);

			selectWindow(files[f]); // could also try selectWindow("Results"); if there is an issue
			run("Close");

			acc = auto_count/manual_count;
			acc_dif = 1-acc;
			abs_acc_dif = abs(acc_dif);
			
			avg = append(avg, acc);
			avg_dif = append(avg_dif, abs_acc_dif);
		}
	} // End of looping through subjects to build arrays for this parameter combination.

	Array.getStatistics(avg, min[0], max[0], mean_acc, std); // could also try (avg, min, max, mean_acc, std); if there is an issue with [0]
	Array.getStatistics(avg_dif, min[0], max[0], mean_acc_dif, std);
	Array.getStatistics(errors, min[0], max[0], mean_err, std);
	Array.getStatistics(error_rate, min[0], max[0], mean_err_rate, std);

	open(merge_folder+best_folder+"Optimization_Avgs.csv");

	Table.set("Avg Acc", c, mean_acc);
	Table.set("Avg Acc Dif", c, mean_acc_dif);
	Table.set("Avg Errors", c, mean_err);
	Table.set("Avg Error Rate", c, mean_err_rate);

	Table.set("Threshold", c, thresh);
	Table.set("Lower Hue", c, lower_hue);
	Table.set("Upper Hue", c, upper_hue);
	Table.set("Pixel Size", c, cell_pixel_size);

	Table.update;
	saveAs("Results", merge_folder+best_folder+"Optimization_Avgs.csv");

	//selectWindow("Results"); // could try uncommenting this line, if there are issues
	//run("Close"); // could try uncommenting this line, if there are issues
} // End of looping through all combinations

setBatchMode(false);











////////////////////// GAMMA  ///////////////////////////////


///////////////////////////////////
///////////// PART 1 //////////////
///////////////////////////////////

//////////// IMPORTANT TASK!!!!!! /////////
// YOU NEED to create these excel sheets ahead of time, one per main merged image:
// merge_folder+optimization_folder+"Optimization_Comparison_"+subject_id+".csv"
// where subject ID is the entire filename except for the "_M" ending.
// Create at least this empty column name in each file; other columns will be added automatically:
// ID
///////////////////////////////////////////

//// SETUP ////

// Main merged files to be automatically counted are here:
merge_folder = "D:/Projects/ARC_Auto_Count_Project/TrainSet/3_MergeGamma/";

// Can only compare to one set of manual counts. Edit folder path appropriately.
// Manual count markers are here:
manual_count_folder = "D:/Projects/ARC_Auto_Count_Project/TrainSet/1_Markers/";

// Save count comparison csv files here, nested under the 3_Merge folder:
optimization_folder = "Optimizations/";

// For trying different thresholds, but not actually accessing any folders:
thresholds = newArray("MaxEntropy", "Moments", "Otsu", "Triangle", "Intermodes");


// Create a function to append values to a growing array.
function append(arr, value) {
	arr2 = newArray(arr.length+1);
     
    for (i=0; i<arr.length; i++) {
		arr2[i] = arr[i];
	}
   	arr2[arr.length] = value;

    return arr2;
}

best_parameters = newArray;
best_subj = newArray;

setBatchMode(true);

marker_list = getFileList(manual_count_folder);
files = getFileList(merge_folder);

for (f=0; f < files.length; f++) {
	if (endsWith(files[f], ".tif")) {
		// SET THE PARAMETERS TO LOOP THROUGH: THRESHOLD, LOWER HUE LIMIT, UPPER HUE LIMIT
		for (t=0; t < thresholds.length; t++){
			for (lower_hue = 50; lower_hue < 75; lower_hue=lower_hue+6) { // 5 options, range of 50-74, up by 6's
				for (upper_hue = 109; upper_hue < 114; upper_hue=upper_hue+2) { // 3 options, range of 109-113, up by 2's

						
///////////////////////////////////////////////////////////////
					// THRESHOLD WITH HUE PARAMETERS
					open(merge_folder+files[f]);
					run("Color Threshold...");
					min=newArray(3);
					max=newArray(3);
					filter=newArray(3);
					a=getTitle();
					run("HSB Stack");
					run("Convert Stack to Images");
					selectWindow("Hue");
					rename("0");
					selectWindow("Saturation");
					rename("1");
					selectWindow("Brightness");
					rename("2");
					min[0]=lower_hue; // Looping through lower values
					max[0]=upper_hue; // Looping through upper values
					filter[0]="pass";
					min[1]=0;
					max[1]=255;
					filter[1]="pass";

					for (i=0;i<2;i++){
						selectWindow(""+i);
						setThreshold(min[i], max[i]);
						run("Convert to Mask");
						if (filter[i]=="stop")  run("Invert");
					}
					imageCalculator("AND create", "0","1");

					selectWindow("2");
					setAutoThreshold(thresholds[t]+" dark"); // Loops through the different thresholds
					setOption("BlackBackground", false);
					run("Convert to Mask");
	
					imageCalculator("AND create", "Result of 0","2");
					for (i=0;i<3;i++){
						selectWindow(""+i);
						close();
					}
					selectWindow("Result of 0");
					close();
	
					selectWindow("Result of Result of 0");
					//run("8-bit");
					// NO USE SAVING THIS THRESHOLDED BINARY IMAGE; THERE WILL BE FAR TOO MANY, AND IMPOSSIBLE TO SAVE THEM IN DIF FOLDERS.
						// saveAs("Tiff", full_folder+files[j]);
						//close();


////////////////////////////////////////////////////////////////////
					// ANALYZE PARTICLES
					
					// SET THE PIXEL SIZE PARAMETER TO LOOP THROUGH
					for (cell_pixel_size = 40; cell_pixel_size < 281; cell_pixel_size = cell_pixel_size + 10) { // 25 options, range of 40-280, up by 10's
						selectWindow("Result of Result of 0");
						run("Analyze Particles...", "size="+cell_pixel_size+"-Infinity pixel show=Outlines exclude add");
						selectWindow("Drawing of Result of Result of 0");
						nROIs = roiManager("count"); // number of objects

						// Make objects bigger to ensure a marker overlaps it
						for (j=0; j < nROIs; j++) {
							roiManager("Select", 0);
							run("Enlarge...", "enlarge=8 pixel");
							roiManager("Add");
							roiManager("Select", 0);
							roiManager("Delete");
						}

						// Fill the particle objects to give the markers a background
						run("Color Picker...");
						setForegroundColor(124, 124, 124); //gray

						for (j=0; j < nROIs; j++) {
							roiManager("Select", j);
							roiManager("Fill");
						}

						// Now to open the markers
						subject_id = substring(files[f],0,lengthOf(files[f])-6); // grab id without "_M" at end
										
						for (e=0; e < marker_list.length; e++) {
							if (endsWith(marker_list[e], ".roi")) {
								if (startsWith(marker_list[e], subject_id)) {
									marker_roi = marker_list[e];
								}
							}
						}
											
						roiManager("Open", manual_count_folder+marker_roi);
						roiManager("Select", nROIs);
						roiManager("Measure");

						markers = Table.size;
						counter_hits = 0;

						for (j=0; j < Table.size; j++) {
							if (Table.get("Mean", j) < 125) { // if the bg is 124 gray (an object) or less, as opposed to 255 white--no object,
								counter_hits++; //mark it as a hit
							}
						}

						selectWindow("Results");
						run("Close");
						
						// Calculate some comparisons between auto and manual count
						
						misses = markers - counter_hits;
						fp = nROIs - counter_hits;
						diff = markers-nROIs;
						abs_diff = abs(diff);
						acc = nROIs/markers;
						acc_dif = 1-acc;
						abs_acc_dif = abs(acc_dif);
						errors = fp + misses;
						error_rate = errors/markers;
						
						// Open a tracking table (csv) and add onto it:										
						open(merge_folder+optimization_folder+"Optimization_Comparison_"+subject_id+"_M.csv");

						Table.set("ID", Table.size, subject_id); // the .size as the index adds a new row
						Table.set("Hits", Table.size-1, counter_hits); // don't want another new row; just add to the previously-made one
						Table.set("Misses", Table.size-1, markers - counter_hits);
						Table.set("False Positives", Table.size-1, nROIs - counter_hits);
						Table.set("Manual Count", Table.size-1, markers);
						Table.set("Auto Count", Table.size-1, nROIs);
						Table.set("Difference", Table.size-1, diff);
						Table.set("Absolute Difference", Table.size-1, abs_diff);
						Table.set("Accuracy", Table.size-1, acc);
						Table.set("Absolute Difference in Accuracy", Table.size-1, abs_acc_dif);
						Table.set("Errors", Table.size-1, errors);
						Table.set("Errors per MC", Table.size-1, error_rate);
						Table.set("Threshold", Table.size-1, thresholds[t]);
						Table.set("Lower Hue", Table.size-1, lower_hue);
						Table.set("Upper Hue", Table.size-1, upper_hue);
						Table.set("Pixel Size", Table.size-1, cell_pixel_size);
						Table.update;
						
						saveAs("Results", merge_folder+optimization_folder+"Optimization_Comparison_"+subject_id+"_M.csv");
						
						selectWindow("Drawing of Result of Result of 0");
						close();
						roiManager("Deselect");
						roiManager("Delete");
						//selectWindow("Results");
						//run("Close");
					} // End pixel size loop
					selectWindow("Result of Result of 0");
					close();
				} // End upper hue limit loop
			} // End lower hue limit loop
		} // End threshold method loop
	} // End work on the image file, if ends with ".tif"
} // End working on all files in the folder list.


///////////////////////////////////////////////////////////////////////



///////////////////////////////////
///////////// PART 2 //////////////
///////////////////////////////////

// FIND BEST PARAMETER ACROSS ALL SUBJECTS, BASED ON AVERAGE ACCURACY AND ERROR ACROSS SUBJECTS

// For one combination, look at every subject's output for that combination
	// Open an individual subject's table of parameter combinations and identify the row that matches the combination in question
	// Save the accuracy, abs dif in acc, number of errors, and error rate for this subject to growing arrays.
// After looping through all subjects, find the mean of those accuracy and error arrays for that combination.
// Save the avgs to a new table that will grow and eventually be as long as the # of combinations.

// Duplicated from Part 1, in case you want to reference the paths again:
merge_folder = "D:/Projects/ARC_Auto_Count_Project/TrainSet/3_MergeGamma/";
optimization_folder = "Optimizations/";
// New folder for holding the most important excel file which aggregates the parameter info across all subjects.
best_folder = "Best_Parameter_Combinations/";

//////////// IMPORTANT TASK!!!!!! /////////
// YOU NEED TO create this one excel doc ahead of time: 
// merge_folder+best_folder+"Optimization_Avgs.csv"
// Create at least this empty column name; others will be added automatically:
// Avg Acc
///////////////////////////////////////////

// Duplicated function from above
function append(arr, value) {
	arr2 = newArray(arr.length+1);
     
    for (i=0; i<arr.length; i++) {
		arr2[i] = arr[i];
	}
   	arr2[arr.length] = value;

    return arr2;
}

files = getFileList(merge_folder+optimization_folder);
for (c=0; c<1875; c++) { //NUMBER OF COMBINATIONS: 5 thresh * 5 lower hue * 3 upper hue * 25 pixel sizes = 1875.
	avg = newArray;
	avg_dif = newArray;
	errors = newArray;
	error_rate = newArray;

	for (f=0; f < files.length; f++) {
		if (endsWith(files[f], ".csv")) {
			open(merge_folder+optimization_folder+files[f]);

			manual_count = Table.get("Manual Count", c);
			auto_count = Table.get("Auto Count", c);
			errors = append(errors, Table.get("Errors", c));
			error_rate = append(error_rate, Table.get("Errors per MC", c));

			thresh = Table.getString("Threshold", c);
			lower_hue = Table.get("Lower Hue", c);
			upper_hue = Table.get("Upper Hue", c);
			cell_pixel_size = Table.get("Pixel Size", c);

			selectWindow(files[f]);
			run("Close");

			acc = auto_count/manual_count;
			acc_dif = 1-acc;
			abs_acc_dif = abs(acc_dif);
			
			avg = append(avg, acc);
			avg_dif = append(avg_dif, abs_acc_dif);
		}
	} // End of looping through subjects to build arrays for this parameter combination.

	Array.getStatistics(avg, min[0], max[0], mean_acc, std);
	Array.getStatistics(avg_dif, min[0], max[0], mean_acc_dif, std);
	Array.getStatistics(errors, min[0], max[0], mean_err, std);
	Array.getStatistics(error_rate, min[0], max[0], mean_err_rate, std);

	open(merge_folder+best_folder+"Optimization_Avgs.csv");

	Table.set("Avg Acc", c, mean_acc);
	Table.set("Avg Acc Dif", c, mean_acc_dif);
	Table.set("Avg Errors", c, mean_err);
	Table.set("Avg Error Rate", c, mean_err_rate);

	Table.set("Threshold", c, thresh);
	Table.set("Lower Hue", c, lower_hue);
	Table.set("Upper Hue", c, upper_hue);
	Table.set("Pixel Size", c, cell_pixel_size);

	Table.update;
	saveAs("Results", merge_folder+best_folder+"Optimization_Avgs.csv");

	//selectWindow("Results");
	//run("Close");
} // End of looping through all combinations

setBatchMode(false);










//////////////////////// MINIMUM ///////////////


///////////////////////////////////
///////////// PART 1 //////////////
///////////////////////////////////

//////////// IMPORTANT TASK!!!!!! /////////
// YOU NEED to create these excel sheets ahead of time, one per main merged image:
// merge_folder+optimization_folder+"Optimization_Comparison_"+subject_id+".csv"
// where subject ID is the entire filename except for the "_M" ending.
// Create at least this empty column name in each file; other columns will be added automatically:
// ID
///////////////////////////////////////////


//// SETUP ////

// Main merged files to be automatically counted are here:
merge_folder = "D:/Projects/ARC_Auto_Count_Project/TrainSet/3_MergeMinimum/";

// Can only compare to one set of manual counts. Edit folder path appropriately.
// Manual count markers are here:
manual_count_folder = "D:/Projects/ARC_Auto_Count_Project/TrainSet/1_Markers/";

// Save count comparison csv files here, nested under the 3_Merge folder:
optimization_folder = "Optimizations/";

// For trying different thresholds, but not actually accessing any folders:
thresholds = newArray("MaxEntropy", "Moments", "Otsu", "Triangle", "Intermodes");


// Create a function to append values to a growing array.
function append(arr, value) {
	arr2 = newArray(arr.length+1);
     
    for (i=0; i<arr.length; i++) {
		arr2[i] = arr[i];
	}
   	arr2[arr.length] = value;

    return arr2;
}

best_parameters = newArray;
best_subj = newArray;

setBatchMode(true);

marker_list = getFileList(manual_count_folder);
files = getFileList(merge_folder);

for (f=0; f < files.length; f++) {
	if (endsWith(files[f], ".tif")) {
		// SET THE PARAMETERS TO LOOP THROUGH: THRESHOLD, LOWER HUE LIMIT, UPPER HUE LIMIT
		for (t=0; t < thresholds.length; t++){
			for (lower_hue = 50; lower_hue < 75; lower_hue=lower_hue+6) { // 5 options, range of 50-74, up by 6's
				for (upper_hue = 109; upper_hue < 114; upper_hue=upper_hue+2) { // 3 options, range of 109-113, up by 2's

						
///////////////////////////////////////////////////////////////
					// THRESHOLD WITH HUE PARAMETERS
					open(merge_folder+files[f]);
					run("Color Threshold...");
					min=newArray(3);
					max=newArray(3);
					filter=newArray(3);
					a=getTitle();
					run("HSB Stack");
					run("Convert Stack to Images");
					selectWindow("Hue");
					rename("0");
					selectWindow("Saturation");
					rename("1");
					selectWindow("Brightness");
					rename("2");
					min[0]=lower_hue; // Looping through lower values
					max[0]=upper_hue; // Looping through upper values
					filter[0]="pass";
					min[1]=0;
					max[1]=255;
					filter[1]="pass";

					for (i=0;i<2;i++){
						selectWindow(""+i);
						setThreshold(min[i], max[i]);
						run("Convert to Mask");
						if (filter[i]=="stop")  run("Invert");
					}
					imageCalculator("AND create", "0","1");

					selectWindow("2");
					setAutoThreshold(thresholds[t]+" dark"); // Loops through the different thresholds
					setOption("BlackBackground", false);
					run("Convert to Mask");
	
					imageCalculator("AND create", "Result of 0","2");
					for (i=0;i<3;i++){
						selectWindow(""+i);
						close();
					}
					selectWindow("Result of 0");
					close();
	
					selectWindow("Result of Result of 0");
					//run("8-bit");
					// NO USE SAVING THIS THRESHOLDED BINARY IMAGE; THERE WILL BE FAR TOO MANY, AND IMPOSSIBLE TO SAVE THEM IN DIF FOLDERS.
						// saveAs("Tiff", full_folder+files[j]);
						//close();


////////////////////////////////////////////////////////////////////
					// ANALYZE PARTICLES
					
					// SET THE PIXEL SIZE PARAMETER TO LOOP THROUGH
					for (cell_pixel_size = 40; cell_pixel_size < 281; cell_pixel_size = cell_pixel_size + 10) { // 25 options, range of 40-280, up by 10's
						selectWindow("Result of Result of 0");
						run("Analyze Particles...", "size="+cell_pixel_size+"-Infinity pixel show=Outlines exclude add");
						selectWindow("Drawing of Result of Result of 0");
						nROIs = roiManager("count"); // number of objects

						// Make objects bigger to ensure a marker overlaps it
						for (j=0; j < nROIs; j++) {
							roiManager("Select", 0);
							run("Enlarge...", "enlarge=8 pixel");
							roiManager("Add");
							roiManager("Select", 0);
							roiManager("Delete");
						}

						// Fill the particle objects to give the markers a background
						run("Color Picker...");
						setForegroundColor(124, 124, 124); //gray

						for (j=0; j < nROIs; j++) {
							roiManager("Select", j);
							roiManager("Fill");
						}

						// Now to open the markers
						subject_id = substring(files[f],0,lengthOf(files[f])-6); // grab id without "_M" at end
										
						for (e=0; e < marker_list.length; e++) {
							if (endsWith(marker_list[e], ".roi")) {
								if (startsWith(marker_list[e], subject_id)) {
									marker_roi = marker_list[e];
								}
							}
						}
											
						roiManager("Open", manual_count_folder+marker_roi);
						roiManager("Select", nROIs);
						roiManager("Measure");

						markers = Table.size;
						counter_hits = 0;

						for (j=0; j < Table.size; j++) {
							if (Table.get("Mean", j) < 125) { // if the bg is 124 gray (an object) or less, as opposed to 255 white--no object,
								counter_hits++; //mark it as a hit
							}
						}

						selectWindow("Results");
						run("Close");
						
						// Calculate some comparisons between auto and manual count
						
						misses = markers - counter_hits;
						fp = nROIs - counter_hits;
						diff = markers-nROIs;
						abs_diff = abs(diff);
						acc = nROIs/markers;
						acc_dif = 1-acc;
						abs_acc_dif = abs(acc_dif);
						errors = fp + misses;
						error_rate = errors/markers;
						
						// Open a tracking table (csv) and add onto it:										
						open(merge_folder+optimization_folder+"Optimization_Comparison_"+subject_id+"_M.csv");

						Table.set("ID", Table.size, subject_id); // the .size as the index adds a new row
						Table.set("Hits", Table.size-1, counter_hits); // don't want another new row; just add to the previously-made one
						Table.set("Misses", Table.size-1, markers - counter_hits);
						Table.set("False Positives", Table.size-1, nROIs - counter_hits);
						Table.set("Manual Count", Table.size-1, markers);
						Table.set("Auto Count", Table.size-1, nROIs);
						Table.set("Difference", Table.size-1, diff);
						Table.set("Absolute Difference", Table.size-1, abs_diff);
						Table.set("Accuracy", Table.size-1, acc);
						Table.set("Absolute Difference in Accuracy", Table.size-1, abs_acc_dif);
						Table.set("Errors", Table.size-1, errors);
						Table.set("Errors per MC", Table.size-1, error_rate);
						Table.set("Threshold", Table.size-1, thresholds[t]);
						Table.set("Lower Hue", Table.size-1, lower_hue);
						Table.set("Upper Hue", Table.size-1, upper_hue);
						Table.set("Pixel Size", Table.size-1, cell_pixel_size);
						Table.update;
						
						saveAs("Results", merge_folder+optimization_folder+"Optimization_Comparison_"+subject_id+"_M.csv");
						
						selectWindow("Drawing of Result of Result of 0");
						close();
						roiManager("Deselect");
						roiManager("Delete");
						//selectWindow("Results");
						//run("Close");
					} // End pixel size loop
					selectWindow("Result of Result of 0");
					close();
				} // End upper hue limit loop
			} // End lower hue limit loop
		} // End threshold method loop
	} // End work on the image file, if ends with ".tif"
} // End working on all files in the folder list.


///////////////////////////////////////////////////////////////////////



///////////////////////////////////
///////////// PART 2 //////////////
///////////////////////////////////

// FIND BEST PARAMETER ACROSS ALL SUBJECTS, BASED ON AVERAGE ACCURACY AND ERROR ACROSS SUBJECTS

// For one combination, look at every subject's output for that combination
	// Open an individual subject's table of parameter combinations and identify the row that matches the combination in question
	// Save the accuracy, abs dif in acc, number of errors, and error rate for this subject to growing arrays.
// After looping through all subjects, find the mean of those accuracy and error arrays for that combination.
// Save the avgs to a new table that will grow and eventually be as long as the # of combinations.

// Duplicated from Part 1, in case you want to reference the paths again:
merge_folder = "D:/Projects/ARC_Auto_Count_Project/TrainSet/3_MergeMinimum/";
optimization_folder = "Optimizations/";
// New folder for holding the most important excel file which aggregates the parameter info across all subjects.
best_folder = "Best_Parameter_Combinations/";

//////////// IMPORTANT TASK!!!!!! /////////
// YOU NEED TO create this one excel doc ahead of time: 
// merge_folder+best_folder+"Optimization_Avgs.csv"
// Create at least this empty column name; others will be added automatically:
// Avg Acc
///////////////////////////////////////////

// Duplicated function from above
function append(arr, value) {
	arr2 = newArray(arr.length+1);
     
    for (i=0; i<arr.length; i++) {
		arr2[i] = arr[i];
	}
   	arr2[arr.length] = value;

    return arr2;
}

files = getFileList(merge_folder+optimization_folder);
for (c=0; c<1875; c++) { //NUMBER OF COMBINATIONS: 5 thresh * 5 lower hue * 3 upper hue * 25 pixel sizes = 1875.
	avg = newArray;
	avg_dif = newArray;
	errors = newArray;
	error_rate = newArray;

	for (f=0; f < files.length; f++) {
		if (endsWith(files[f], ".csv")) {
			open(merge_folder+optimization_folder+files[f]);

			manual_count = Table.get("Manual Count", c);
			auto_count = Table.get("Auto Count", c);
			errors = append(errors, Table.get("Errors", c));
			error_rate = append(error_rate, Table.get("Errors per MC", c));

			thresh = Table.getString("Threshold", c);
			lower_hue = Table.get("Lower Hue", c);
			upper_hue = Table.get("Upper Hue", c);
			cell_pixel_size = Table.get("Pixel Size", c);

			selectWindow(files[f]);
			run("Close");

			acc = auto_count/manual_count;
			acc_dif = 1-acc;
			abs_acc_dif = abs(acc_dif);
			
			avg = append(avg, acc);
			avg_dif = append(avg_dif, abs_acc_dif);
		}
	} // End of looping through subjects to build arrays for this parameter combination.

	Array.getStatistics(avg, min[0], max[0], mean_acc, std);
	Array.getStatistics(avg_dif, min[0], max[0], mean_acc_dif, std);
	Array.getStatistics(errors, min[0], max[0], mean_err, std);
	Array.getStatistics(error_rate, min[0], max[0], mean_err_rate, std);

	open(merge_folder+best_folder+"Optimization_Avgs.csv");

	Table.set("Avg Acc", c, mean_acc);
	Table.set("Avg Acc Dif", c, mean_acc_dif);
	Table.set("Avg Errors", c, mean_err);
	Table.set("Avg Error Rate", c, mean_err_rate);

	Table.set("Threshold", c, thresh);
	Table.set("Lower Hue", c, lower_hue);
	Table.set("Upper Hue", c, upper_hue);
	Table.set("Pixel Size", c, cell_pixel_size);

	Table.update;
	saveAs("Results", merge_folder+best_folder+"Optimization_Avgs.csv");

	//selectWindow("Results");
	//run("Close");
} // End of looping through all combinations

setBatchMode(false);










///////////////////// GMA /////////////////////


///////////////////////////////////
///////////// PART 1 //////////////
///////////////////////////////////

//////////// IMPORTANT TASK!!!!!! /////////
// YOU NEED to create these excel sheets ahead of time, one per main merged image:
// merge_folder+optimization_folder+"Optimization_Comparison_"+subject_id+".csv"
// where subject ID is the entire filename except for the "_M" ending.
// Create at least this empty column name in each file; other columns will be added automatically:
// ID
///////////////////////////////////////////


//// SETUP ////

// Main merged files to be automatically counted are here:
merge_folder = "D:/Projects/ARC_Auto_Count_Project/TrainSet/3_MergeGMA/";

// Can only compare to one set of manual counts. Edit folder path appropriately.
// Manual count markers are here:
manual_count_folder = "D:/Projects/ARC_Auto_Count_Project/TrainSet/1_Markers/";

// Save count comparison csv files here, nested under the 3_Merge folder:
optimization_folder = "Optimizations/";

// For trying different thresholds, but not actually accessing any folders:
thresholds = newArray("MaxEntropy", "Moments", "Otsu", "Triangle", "Intermodes");


// Create a function to append values to a growing array.
function append(arr, value) {
	arr2 = newArray(arr.length+1);
     
    for (i=0; i<arr.length; i++) {
		arr2[i] = arr[i];
	}
   	arr2[arr.length] = value;

    return arr2;
}

best_parameters = newArray;
best_subj = newArray;

setBatchMode(true);

marker_list = getFileList(manual_count_folder);
files = getFileList(merge_folder);

for (f=0; f < files.length; f++) {
	if (endsWith(files[f], ".tif")) {
		// SET THE PARAMETERS TO LOOP THROUGH: THRESHOLD, LOWER HUE LIMIT, UPPER HUE LIMIT
		for (t=0; t < thresholds.length; t++){
			for (lower_hue = 50; lower_hue < 75; lower_hue=lower_hue+6) { // 5 options, range of 50-74, up by 6's
				for (upper_hue = 109; upper_hue < 114; upper_hue=upper_hue+2) { // 3 options, range of 109-113, up by 2's

						
///////////////////////////////////////////////////////////////
					// THRESHOLD WITH HUE PARAMETERS
					open(merge_folder+files[f]);
					run("Color Threshold...");
					min=newArray(3);
					max=newArray(3);
					filter=newArray(3);
					a=getTitle();
					run("HSB Stack");
					run("Convert Stack to Images");
					selectWindow("Hue");
					rename("0");
					selectWindow("Saturation");
					rename("1");
					selectWindow("Brightness");
					rename("2");
					min[0]=lower_hue; // Looping through lower values
					max[0]=upper_hue; // Looping through upper values
					filter[0]="pass";
					min[1]=0;
					max[1]=255;
					filter[1]="pass";

					for (i=0;i<2;i++){
						selectWindow(""+i);
						setThreshold(min[i], max[i]);
						run("Convert to Mask");
						if (filter[i]=="stop")  run("Invert");
					}
					imageCalculator("AND create", "0","1");

					selectWindow("2");
					setAutoThreshold(thresholds[t]+" dark"); // Loops through the different thresholds
					setOption("BlackBackground", false);
					run("Convert to Mask");
	
					imageCalculator("AND create", "Result of 0","2");
					for (i=0;i<3;i++){
						selectWindow(""+i);
						close();
					}
					selectWindow("Result of 0");
					close();
	
					selectWindow("Result of Result of 0");
					//run("8-bit");
					// NO USE SAVING THIS THRESHOLDED BINARY IMAGE; THERE WILL BE FAR TOO MANY, AND IMPOSSIBLE TO SAVE THEM IN DIF FOLDERS.
						// saveAs("Tiff", full_folder+files[j]);
						//close();


////////////////////////////////////////////////////////////////////
					// ANALYZE PARTICLES
					
					// SET THE PIXEL SIZE PARAMETER TO LOOP THROUGH
					for (cell_pixel_size = 40; cell_pixel_size < 281; cell_pixel_size = cell_pixel_size + 10) { // 25 options, range of 40-280, up by 10's
						selectWindow("Result of Result of 0");
						run("Analyze Particles...", "size="+cell_pixel_size+"-Infinity pixel show=Outlines exclude add");
						selectWindow("Drawing of Result of Result of 0");
						nROIs = roiManager("count"); // number of objects

						// Make objects bigger to ensure a marker overlaps it
						for (j=0; j < nROIs; j++) {
							roiManager("Select", 0);
							run("Enlarge...", "enlarge=8 pixel");
							roiManager("Add");
							roiManager("Select", 0);
							roiManager("Delete");
						}

						// Fill the particle objects to give the markers a background
						run("Color Picker...");
						setForegroundColor(124, 124, 124); //gray

						for (j=0; j < nROIs; j++) {
							roiManager("Select", j);
							roiManager("Fill");
						}

						// Now to open the markers
						subject_id = substring(files[f],0,lengthOf(files[f])-6); // grab id without "_M" at end
										
						for (e=0; e < marker_list.length; e++) {
							if (endsWith(marker_list[e], ".roi")) {
								if (startsWith(marker_list[e], subject_id)) {
									marker_roi = marker_list[e];
								}
							}
						}
											
						roiManager("Open", manual_count_folder+marker_roi);
						roiManager("Select", nROIs);
						roiManager("Measure");

						markers = Table.size;
						counter_hits = 0;

						for (j=0; j < Table.size; j++) {
							if (Table.get("Mean", j) < 125) { // if the bg is 124 gray (an object) or less, as opposed to 255 white--no object,
								counter_hits++; //mark it as a hit
							}
						}

						selectWindow("Results");
						run("Close");
						
						// Calculate some comparisons between auto and manual count
						
						misses = markers - counter_hits;
						fp = nROIs - counter_hits;
						diff = markers-nROIs;
						abs_diff = abs(diff);
						acc = nROIs/markers;
						acc_dif = 1-acc;
						abs_acc_dif = abs(acc_dif);
						errors = fp + misses;
						error_rate = errors/markers;
						
						// Open a tracking table (csv) and add onto it:										
						open(merge_folder+optimization_folder+"Optimization_Comparison_"+subject_id+"_M.csv");

						Table.set("ID", Table.size, subject_id); // the .size as the index adds a new row
						Table.set("Hits", Table.size-1, counter_hits); // don't want another new row; just add to the previously-made one
						Table.set("Misses", Table.size-1, markers - counter_hits);
						Table.set("False Positives", Table.size-1, nROIs - counter_hits);
						Table.set("Manual Count", Table.size-1, markers);
						Table.set("Auto Count", Table.size-1, nROIs);
						Table.set("Difference", Table.size-1, diff);
						Table.set("Absolute Difference", Table.size-1, abs_diff);
						Table.set("Accuracy", Table.size-1, acc);
						Table.set("Absolute Difference in Accuracy", Table.size-1, abs_acc_dif);
						Table.set("Errors", Table.size-1, errors);
						Table.set("Errors per MC", Table.size-1, error_rate);
						Table.set("Threshold", Table.size-1, thresholds[t]);
						Table.set("Lower Hue", Table.size-1, lower_hue);
						Table.set("Upper Hue", Table.size-1, upper_hue);
						Table.set("Pixel Size", Table.size-1, cell_pixel_size);
						Table.update;
						
						saveAs("Results", merge_folder+optimization_folder+"Optimization_Comparison_"+subject_id+"_M.csv");
						
						selectWindow("Drawing of Result of Result of 0");
						close();
						roiManager("Deselect");
						roiManager("Delete");
						//selectWindow("Results");
						//run("Close");
					} // End pixel size loop
					selectWindow("Result of Result of 0");
					close();
				} // End upper hue limit loop
			} // End lower hue limit loop
		} // End threshold method loop
	} // End work on the image file, if ends with ".tif"
} // End working on all files in the folder list.


///////////////////////////////////////////////////////////////////////



///////////////////////////////////
///////////// PART 2 //////////////
///////////////////////////////////

// FIND BEST PARAMETER ACROSS ALL SUBJECTS, BASED ON AVERAGE ACCURACY AND ERROR ACROSS SUBJECTS

// For one combination, look at every subject's output for that combination
	// Open an individual subject's table of parameter combinations and identify the row that matches the combination in question
	// Save the accuracy, abs dif in acc, number of errors, and error rate for this subject to growing arrays.
// After looping through all subjects, find the mean of those accuracy and error arrays for that combination.
// Save the avgs to a new table that will grow and eventually be as long as the # of combinations.

// Duplicated from Part 1, in case you want to reference the paths again:
merge_folder = "D:/Projects/ARC_Auto_Count_Project/TrainSet/3_MergeGMA/";
optimization_folder = "Optimizations/";
// New folder for holding the most important excel file which aggregates the parameter info across all subjects.
best_folder = "Best_Parameter_Combinations/";

//////////// IMPORTANT TASK!!!!!! /////////
// YOU NEED TO create this one excel doc ahead of time: 
// merge_folder+best_folder+"Optimization_Avgs.csv"
// Create at least this empty column name; others will be added automatically:
// Avg Acc
///////////////////////////////////////////

// Duplicated function from above
function append(arr, value) {
	arr2 = newArray(arr.length+1);
     
    for (i=0; i<arr.length; i++) {
		arr2[i] = arr[i];
	}
   	arr2[arr.length] = value;

    return arr2;
}

files = getFileList(merge_folder+optimization_folder);
for (c=0; c<1875; c++) { //NUMBER OF COMBINATIONS: 5 thresh * 5 lower hue * 3 upper hue * 25 pixel sizes = 1875.
	avg = newArray;
	avg_dif = newArray;
	errors = newArray;
	error_rate = newArray;

	for (f=0; f < files.length; f++) {
		if (endsWith(files[f], ".csv")) {
			open(merge_folder+optimization_folder+files[f]);

			manual_count = Table.get("Manual Count", c);
			auto_count = Table.get("Auto Count", c);
			errors = append(errors, Table.get("Errors", c));
			error_rate = append(error_rate, Table.get("Errors per MC", c));

			thresh = Table.getString("Threshold", c);
			lower_hue = Table.get("Lower Hue", c);
			upper_hue = Table.get("Upper Hue", c);
			cell_pixel_size = Table.get("Pixel Size", c);

			selectWindow(files[f]);
			run("Close");

			acc = auto_count/manual_count;
			acc_dif = 1-acc;
			abs_acc_dif = abs(acc_dif);
			
			avg = append(avg, acc);
			avg_dif = append(avg_dif, abs_acc_dif);
		}
	} // End of looping through subjects to build arrays for this parameter combination.

	Array.getStatistics(avg, min[0], max[0], mean_acc, std);
	Array.getStatistics(avg_dif, min[0], max[0], mean_acc_dif, std);
	Array.getStatistics(errors, min[0], max[0], mean_err, std);
	Array.getStatistics(error_rate, min[0], max[0], mean_err_rate, std);

	open(merge_folder+best_folder+"Optimization_Avgs.csv");

	Table.set("Avg Acc", c, mean_acc);
	Table.set("Avg Acc Dif", c, mean_acc_dif);
	Table.set("Avg Errors", c, mean_err);
	Table.set("Avg Error Rate", c, mean_err_rate);

	Table.set("Threshold", c, thresh);
	Table.set("Lower Hue", c, lower_hue);
	Table.set("Upper Hue", c, upper_hue);
	Table.set("Pixel Size", c, cell_pixel_size);

	Table.update;
	saveAs("Results", merge_folder+best_folder+"Optimization_Avgs.csv");

	//selectWindow("Results");
	//run("Close");
} // End of looping through all combinations

setBatchMode(false);


