# ImageJ_AutoCount
Automatically count cells in microscopy images with optimized parameter settings in ImageJ

### Table of Contents
1. [Purpose](#purpose)
2. [Main Project Folders](#main-project-folders)
3. [User Inputs](#user-inputs)
4. [Further Instructions](#further-instructions)
5. [References](#references)

## Purpose
The ImageJ macros contained in this repository are useful for identifying objects that match a limited color range within an image, such as green cells in a microscopy image that overlays two channels - blue cell nuclei (present in every cell, very unlikely to result in background artifacts) and yellow cells of interest (stains cell nucleus and processes, very likely to result in background artifacts). Identifying the green areas where the yellow cells of interest overlap a blue marker that is almost guaranteed to be a true cell body can improve cell detection above standard detection methods that traditionally would apply a single-channel intensity threshold to the yellow channel to remove the processes and background, which are thought to be dimmer than the brightly-stained cell bodies (though this is not always the case, and bright artifacts are common).

These macros automatically detect and count the number of objects that meet specified color threshold and object size settings. Image processing and object detection settings are optimized to ensure the most accurate automated count possible when compared to a manual count conducted by a trained observer.

## Main Project Folders
There are 3 main folders in this repository:
1. Projects/ARC_Auto_Count_Project
1. Projects/ARC_Auto_Count_Project_EXAMPLE_SETUP
1. Projects/ARC_Auto_Count_Project_EXAMPLE_COMPLETE

The first folder is ready for users to use with their own data sets. The second folder, EXAMPLE_SETUP, provides example images so users can try running the macros on their own devices (starting with merged images and the second macro). The third folder, EXAMPLE_COMPLETE, runs the example images through the full set of macros (starting with the second macro) and provides a full set of output files.

Macros for each case are stored in the "Macros" folder within each of those three folders.

## User Inputs
Users should come prepared with raw images from the scanner (separate images for the two channels of interest) that have been roughly cropped to an area just larger than the desired size (the desired cropping area set in the macro is 1125 x 1125 pixels, but this can be edited), saved in the ".tif" file format. These images should be copied into the folder, Projects/ARC_Auto_Count_Project/FullSet/2_Originals. The first macro ("Step1") will crop and merge the channels for these original source images.

Alternatively, if the user has images that are already cropped and merged, the user can save them into the folder, "3_MergeRaw" and begin with the second macro ("Step2"). The two "EXAMPLE" project folders use this input option as a starting point.

## Example Images are not real microscopy images
The example images provided in the "Projects/ARC_Auto_Count_Project_EXAMPLE_SETUP" and "Projects/ARC_Auto_Count_Project_EXAMPLE_COMPLETE" folders are not real microscopy images of cells. They are loosely based on images of microglia found in the arcuate nucleus of the hypothalamus (hence the abbreviation "ARC" in the folder name, "ARC_Auto_Count_Project"), where microglia were stained with Iba1 (pseudocolored yellow), and cell nuclei were stained with DAPI (pseudocolored cyan). The example images are completely fabricated and do not contain any pixels, forms, or other information directly copied from a true microscopy image. They are meant to represent the general look of microscopy images of microglia cells, but they do not contain real microglia cells. Thus, the markers that were manually placed over each example image are not marking microglia, but rather any small, green oval that artistically represents a microglia cell for the purposes of testing the macro scripts. Markers cannot be used to inform users of the identifiable characteristics of microglia, as no microglia appear in the images. Additionally, markers were intentionally placed on objects that do not resemble the vast majority of the other small, green ovals (e.g. blatantly wrong size, shape, or color), and markers were intentionally omitted from a small number of objects that *do* resemble the vast majority of the other small, green ovals. These intentional "mistakes" better represent the true diversity of "real" cells and trained observer error, and they provide a realistic object detection challenge that will yield accuracies below 100%, which will help to differentiate between the various combinations of image processing settings.

## Further Instructions
Each of the macros, to be run in numbered order, contain further instructions on how to prepare for the macro (create files and folder structures), edit the settings, and run the code. These instructions are contained in full at the top of each macro script, and they are often repeated throughout the code as reminders. While the scripts are useful for applying ImageJ settings to large batches of images, there are several intermediary steps that must be accomplished by the user between macros. The general workflow is summarized below:

1. The user must copy images into the folder structure in one of two ways. (1.) The user may place original, single-channel images (larger than the desired dimensions for each image to be cropped to, currently set to 1125 x 1125 pixels), in the folder, FullSet/2_Originals (then proceed to this workflow's step 2). (2.) The user may place cropped, merged images into the folder, FullSet/3_MergeRaw (then proceed to this workflow's step 3).
1. Run the first macro, `Step1_Crop_Merge.ijm`. Macros can be run by dragging the file into ImageJ (which opens the script editor), selecting IJ1 from the Language dropdown menu, then selecting Run from the Run drop-down menu. Users can also highlight desired lines of code and click "Run Selection" from the Run drop-down menu.
1. Look at the images in FullSet/3_MergeRaw. Select a subset (ideally 20 images; considering balancing this set by grabbing images from different subjects, groups, genders, image qualities, etc.) to be used for training the optimization procedure, which is the process of trying many combinations of image processing and object detection parameter settings on these images to see which combination performs the best. Copy these images into the folder, TrainSet/3_MergeRaw. Select another subset (ideally 20 images; cannot reuse any images from the TrainSet) to be used for validation of the optimized parameter combination (i.e. see whether the combination that yielded the highest accuracy across the TrainSet still achieves an accuracy above 80% on the TestSet). Copy these images into the folder, TestSet/3_MergeRaw.
1. Manually detect objects for each image in the TrainSet. Open each image in ImageJ, select the multi-point marker tool, and click to place a marker over the center of each object. Save the set of markers to the TrainSet/1_Markers folder by clicking Edit > Selection > Add to Manager, then click on the number ID representing the set of markers, then click More > Save. Give the filename the same name as the image's filename, by replacing the "_M.tif" with "_markers.roi". Close the image and the ROI manager, then open the next image and repeat the process.
1. Repeat step 4 (manually detecting objects with markers) for the TestSet, saving the markers into the TestSet/1_Markers folder.
1. Run the second macro, `Step2_Optimizing_All_Parameters_Train.ijm`. Make sure the placeholder csv files are already created, named, and present within the appropriate folders (see the notes in the macro for more information).
1. Create a new csv file named, "Optimization_Avgs_All_ProcMeth_MergedByHand.csv" (or a name of your choosing) and save it in the TestSet folder. Open each "Optimization_Avgs.csv" file from the "Best_Parameter_Combinations" subfolder in each processing method folder (e.g. "3_MergeRaw," "3_MergeMinimum," etc.) within the TrainSet folder. These files may need to be opened one at a time. Copy the contents of each file into the new csv file. The column names need only appear once, at the top, and the contents of the Optimization_Avgs.csv files can be appended in subsequent rows. Then, sort the contents by the column name, "Avg Acc Dif" from low to high. As long as the first entry is less than 0.2, then the absolute difference in the accuracy of that parameter combination from the manual count (averaged across all images) was less than 20%, meaning that the combination was over 80% accurate on average. Using an automated method that is at least 80% accurate is good practice. Remember the parameter settings for this combination, as other macros will need to be updated to reflect these settings. **NOTE:** The absolute value of the difference in accuracy is necessary because an automated count may be larger or smaller than the manual count, so dividing the counts may lead to an accuracy that is greater than or less than 100%. Averaging an accuracy of 80% for one image with an accuracy of 120% for another would make it seem like the combination was 100% accurate on average, whereas averaging the absolute difference in accuracy for both of those images (-0.2 and +0.2, or an absolute difference of 0.2 for each) would show that the accuracy was off by about 20% on average, or that the combination achieved an accuracy of 80% on average.
1. Run the third macro, `Step3_Optimizing_All_Parameters_Test.ijm`, on the TestSet, making sure to update the code and folder structure with the parameter settings of the most accurate combination. Make sure the placeholder csv files are already created, named, and present within the appropriate folders (see the notes in the macro for more information).
1. Open the "Optimization_Avgs.csv" file in the Best_Paramter_Combinations folder within the appropriate processing method folder of the TestSet folder. Ensure the cell under the "Avg Acc Dif" column is less than 0.2, indicating that the combination was over 80% accurate when validated on the new set of Test images.
3. To get a closer look at how the best combination fared across each image, run the fourth macro, `Step4_OPTIONAL_Performance_of_1_Combination_on_all_images.ijm`. This can ensure the combination was roughly accurate for each image, rather than being highly accurate for some images and inaccurate for others (with these differences averaging out to make the combination appear to be accurate). Update the code to reflect the parameters of the combination to assess.
1. Run the fifth and final macro, `Step5_FullSet_Process_Threshold_AutoCount_BestSettings.ijm` after updating the code and folder structure to reflect the parameters of the combination that has been optimized for the image set. Make sure the placeholder csv files are already created, named, and present within the appropriate folders (see the notes in the macro for more information).
1. Open the csv file that is stored in the FullSet/5_Counts folder. This file recorded the automated count (number of objects detected) for each image when running the fifth macro, which used the image processing and object detection parameters that were optimized for the data set. This is the final output. Use this file for any further analysis that needs information about the number of objects in each image.

## References
These macros were used to automatically detect cells in microscopy images. Manuscript under review.

