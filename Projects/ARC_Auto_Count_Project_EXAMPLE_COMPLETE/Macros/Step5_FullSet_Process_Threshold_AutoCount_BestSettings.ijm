// 5/22/2023 - Run the optimized settings on the full set of images to generate automated counts for the final data set.

// NOTES FOR THE COMPLETED EXAMPLE:
// The "best" combination (lowest average absolute difference in accuracy, aka "Avg Acc Dif") of my limited example options was
// PROCESSING METHOD: Gamma
// THRESHOLD: MaxEntropy
// LOWER HUE DISPLAY LIMIT: 58
// UPPER HUE DISPLAY LIMIT: 113
// PIXEL SIZE: 100
// This combination was 99.5% accurate on the Train set and 79.3% accurate for the Test set.
// For real analyses, the Test set accuracy should be 80% or greater, but we will continue on with the idenitified
// combination because 79.3% was close enough for this limited and highly fabricated example.
// The first step is to create a new folder for images to undergo Gamma processing, "3_MergeGamma," and update the
// code to implement that processing.
// I have also updated the output image folder name to reflect the true combination. Instead of "4_MaxEnt50109110"
// it is now "4_Gamma_MaxEnt58113100" and I have updated the code to point to that new folder path.
// Lastly, I will update the code to reflect the true parameters of the "best" combination, detailed above.


////////////////////////////////


//// IMPORTANT NOTES ////

// 1. Update the following code with the correct settings.
// 2. See notes at the beginning of each section for information about what to update.
// 3. The final OUTPUT of this macro is a csv file with the number of automatically-counted cells in each image, saved here:
//    "D:/Projects/ARC_Auto_Count_Project/FullSet/5_Counts/AutoCellCount_size"+cell_pixel_size+"_"+date+".csv"
//    where cell_pixel_size is the number of square pixels used during "Analyze Particles," and date is the date you set (e.g. today).
// 4. If you encounter problems, try running each section separately (highlight the text and run just that selection).


/////////////////////
////// PROCESS //////
/////////////////////

// All processing options have been commented out in case "Raw" was determined to be the best setting.
// Remove the comment markers, "//" before the lines that create the preferred processing option, if different from Raw.
// Make sure the new processing method folder has been created.

setBatchMode(true);

proj_folder = "D:/Projects/ARC_Auto_Count_Project_EXAMPLE_COMPLETE/FullSet/";
files = getFileList(proj_folder+"3_MergeRaw/");

for (i=0; i < files.length; i++) {

	if (endsWith(files[i], ".tif")) {

////// MINIMUM	
//		open(proj_folder+"3_MergeRaw/"+files[i]);
//		run("Minimum...", "radius=5");
//		saveAs("Tiff", proj_folder+"3_MergeMinimum/"+files[i]);
//		close();

////// GAMMA
		open(proj_folder+"3_MergeRaw/"+files[i]);
//		run("Duplicate...", "title=Dup");
//		selectWindow(files[i]);	
		run("Gamma...", "value=0.50");
		saveAs("Tiff", proj_folder+"3_MergeGamma/"+files[i]);
        close();

////// GMA (GAMMA-MINIMUM-AVERAGED-WITH-RAW)
//		open(proj_folder+"3_MergeRaw/"+files[i]);
//		run("Duplicate...", "title=Dup");
//		selectWindow(files[i]);	
//		run("Gamma...", "value=0.50");
//		run("Minimum...", "radius=5");
//		imageCalculator("Average create", "Dup", files[i]);
//		selectWindow("Result of Dup");
//		saveAs("Tiff", proj_folder+"3_MergeGMA/"+files[i]);
//		close();
//		close();
//		close();
	}
}

setBatchMode(false);





///////////////////////
////// THRESHOLD //////
///////////////////////

// Have all merged images in the appropriate merge_folder - update this path if the processing option was not Raw.
// Adjust the hue display limit settings. Code currently sets lower=50, upper=109.
// Update the thresholding algorithm, which is currently set to Maximum Entropy.
// Create an empty threshold folder (e.g. MaxEntropy) for images to be deposited into.

// UPDATE THESE IF NEEDED:
huelower = 58;
hueupper = 113;
thresh = "MaxEntropy";


merge_folder = "D:/Projects/ARC_Auto_Count_Project_EXAMPLE_COMPLETE/FullSet/3_MergeRaw/";
thresh_folder = "D:/Projects/ARC_Auto_Count_Project_EXAMPLE_COMPLETE/FullSet/4_Gamma_MaxEnt58113100/";

setBatchMode(true);

files = getFileList(merge_folder);
			
for (j=0; j < files.length; j++) {

	if (endsWith(files[j], ".tif")) {
		
		open(merge_folder+files[j]);

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
		min[0]=huelower; // =50; // LOWER HUE DISPLAY LIMIT
		max[0]=hueupper; // =109; // UPPER HUE DISPLAY LIMIT
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
		setAutoThreshold(thresh+" dark"); // ("MaxEntropy dark"); // THRESHOLDING ALGORITHM
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
		saveAs("Tiff", thresh_folder+files[j]);
		close();
	}
}
		


setBatchMode(false);





//////////////////////////////////
////// AUTOMATED CELL COUNT //////
//////////////////////////////////

// Update the folder path, cell_pixel_size, and date (see below) if needed.
// Create a folder to hold the Counts data.

thresh_folder = "D:/Projects/ARC_Auto_Count_Project_EXAMPLE_COMPLETE/FullSet/4_Gamma_MaxEnt58113100/";
count_folder = "D:/Projects/ARC_Auto_Count_Project_EXAMPLE_COMPLETE/FullSet/5_Counts/";
cell_pixel_size = 100;
date = "20230823";

setBatchMode(true);
	
files = getFileList(thresh_folder);
		
for (i=0; i < files.length; i++) {

	if (endsWith(files[i], ".tif")) {
		
		open(thresh_folder+files[i]);

		run("Analyze Particles...", "size="+cell_pixel_size+"-Infinity pixel show=Outlines exclude summarize");
		selectWindow("Drawing of "+files[i]);
		close();
		selectWindow(files[i]);
		close();

		selectWindow("Summary");
		
		saveAs("Results", count_folder+"AutoCellCount_size"+cell_pixel_size+"_"+date+".csv");
		//don't close it; let it add on new rows and continuously overwrite the csv file.
		Table.rename("AutoCellCount_size"+cell_pixel_size+"_"+date+".csv", "Summary");
	}
}

//or, save it at the end if continuously doesn't work:
//selectWindow("Summary");
//saveAs("Results", count_folder+"AutoCellCount_size"+cell_pixel_size+"_"+date+".csv");


setBatchMode(false);



