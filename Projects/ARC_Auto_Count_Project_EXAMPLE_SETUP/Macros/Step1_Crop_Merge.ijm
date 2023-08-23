// 5/22/2023 - Initial Macro to prepare all microscopy images for optimization and/or final processing.

// IMPORTANT NOTES:
// 1. Run this macro first. Then perform optimization or the final analysis on the merged images created from this macro.
// 2. Folder paths are hardcoded below. Please update them to align with your folder naming structure.
// 3. The LENGTH of the file name for each image is hardcoded based on this example: "00000_1.1_01_ARC1_C0001.tif"
//    The code removes the last 9 characters ("C0001.tif") and appends "M.tif" to the end, to indicate that the image
//    no longer represents just the DAPI channel ("C0001") but instead is the merged image ("M"). Please update the code
//    to reflect the number of characters to remove at the end, or change your filenames to have 9 removable characters.
// 4. After this code finishes running, you must decide which images to select for the train and test sets (20 images each)
//    and copy them into separate "TrainSet" and "TestSet" folder structures manually, as the code cannot predict your decision.
// 5. An optional function is included at the bottom. If you would like to create a "composite" image that overlays the two
//    channels and lets you adjust the brightness of each independently, simply remove the comment marks to run that part of
//    the code. It currently points to the FullSet folder of all original images, but you may wish to copy just the original
//    images for your Train and Test sets into a different folder, and update that hardcoded folder path, to make composites
//    for just that subset. Making composites can help immensely when manually identifying cells and placing accurate markers.

// PURPOSE:
// This macro crops images to exactly 1125 x 1125 pixels (standardized area), then merges the DAPI & Iba1 channels in pseudocolors.

//////////////////
////// CROP //////
//////////////////

// First, use Olympus Stream View to crop the 20x immunofluorescent images to roughly the correct standard-sized box areas,
// just over 1125 x 1125 pixels, and save the DAPI and Iba1 channels as independent tif images in the source folder ("originals"):
// "D:/Projects/ARC_Auto_Count_Project/FullSet/1_Originals/"
// These files are usually named "filename_001" for DAPI and "filename_002" for Iba1, with both channels present within the same folder.
// Then, this macro will crop those images down to EXACTLY 1125 x 1125 pixels, saved into a "cropped" folder.

setBatchMode(true);

source_folder = newArray("D:/Projects/ARC_Auto_Count_Project/FullSet/1_Originals/");
crop_folder = "D:/Projects/ARC_Auto_Count_Project/FullSet/2_Cropped/";

for (s = 0; s < source_folder.length; s++) {

	source_files = getFileList(source_folder[s]);

	for (i=0; i < source_files.length; i++) {

		if (endsWith(source_files[i], "1.tif") || endsWith(source_files[i], "2.tif")) {

			run("Bio-Formats", "open="+source_folder[s]+source_files[i]+" autoscale color_mode=Default crop rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT x_coordinate_1=0 y_coordinate_1=0 width_1=1125 height_1=1125");
			saveAs("Tiff", crop_folder+source_files[i]);
			close();
		}
	}
}

setBatchMode(false);



////////////////////////////////////////////////////
////// MERGE CHANNELS, cyan=DAPI, yellow=IBA1 //////
////////////////////////////////////////////////////

// These merged images will be considered "raw," and will be the basis for all further steps (extra processing, thresholding, etc.).
// Output merged images will be saved to the following folder by default:
// "D:/Projects/ARC_Auto_Count_Project/FullSet/3_MergeRaw/"
// Once this step is complete, select the 20 train and 20 test merged images that will be used for optimization,
// and copy them into new folders following the structure,
// "D:/Projects/ARC_Auto_Count_Project/TrainSet/3_MergeRaw/"
// "D:/Projects/ARC_Auto_Count_Project/TestSet/3_MergeRaw/"
// The final processing and analysis will occur on the merged images in the "FullSet" folder structure.

crop_folder = "D:/Projects/ARC_Auto_Count_Project/FullSet/2_Cropped/";
merge_folder = "D:/Projects/ARC_Auto_Count_Project/FullSet/3_MergeRaw/";
files = getFileList(crop_folder);

setBatchMode(true);

for (j=0; j < files.length; j++) {
	if (endsWith(files[j], ".tif")) {

		open(crop_folder+files[j]);
		open(crop_folder+files[j+1]);

		run("Merge Channels...", "c5="+files[j]+" c7="+files[j+1]);
		
		selectWindow("RGB");
		saveAs("Tiff", merge_folder+substring(files[j],0,lengthOf(files[j])-9)+"M.tif");
		close();
	}
	j++;
}

setBatchMode(false);


////////////////////////////////////////////////////////////////////

//////////////////
//// OPTIONAL ////
//////////////////

////////////////////////////////////////////////////////////////////
////// CREATE COMPOSITE IMAGE FOR MANUAL VIEWING AND COUNTING //////
////////////////////////////////////////////////////////////////////

// Use this macro to merge the two channels (DAPI and Iba1) to visualize the microglia better.
// Composite images are useful because the brightness of each channel can be adjusted independently and visualized together immediately.
// This step is optional, as the previously-made flattened-merged images may be sufficient for your purposes.
// These composite images can be used during optimization and during the final analysis:
// OPTIMIZATION: A trained observer will be able to open each image independently and manually place markers in the center of microglia somas.
// FINAL ANALYSIS: Analysts can open these images to visually check that the automated count seems realistic, reject images that appear too
// blurry or low quality for a trustworthy count, and select images that would be good for publication with fine-tuning of display limits.
// Remove the comments ("//") before each line before running.


//setBatchMode(true);

//crop_folder = "D:/Projects/ARC_Auto_Count_Project/FullSet/2_Cropped/";
//comp_folder = "D:/Projects/ARC_Auto_Count_Project/TrainSet/2_Composites/";

//files = getFileList(crop_folder);

//for (j=0; j < files.length; j++) {
//	if (endsWith(files[j], ".tif")) {
//
//		open(crop_folder+files[j]);
//		open(crop_folder+files[j+1]);
//
//		run("Merge Channels...", "c5="+files[j]+" c7="+files[j+1]+" create");
//		
//		selectWindow("Composite");
//		saveAs("Tiff", comp_folder+substring(files[j],0,lengthOf(files[j])-9)+"Comp.tif");
//		close();
//	}
//	j++;
//}

//setBatchMode(false);


