%This code detects the eye gaze of the patient and controls the
%prototype(wheelchair) on the basis of datected eyegaze.
%Detection and working of the code is made self explanatory using GUI. 

cam = webcam()%initializes Webcam object
a = arduino();%create an arduino object under variable 'a'
writeDigitalPin(a,'D8',0);%Digital pins being intialized to ground or LOW logic level
writeDigitalPin(a,'D12',0);
writeDigitalPin(a,'D11',0);
writeDigitalPin(a,'D10',0);
writeDigitalPin(a,'D9',0);
right=imread('RIGHT.jpg');%stores image for RIGHT direction
left=imread('LEFT.jpg');%stores images for LEFT direction
noface=imread('no_face.jpg');%stores images for NO FACE status
straight=imread('STRAIGHT.jpg');%stores image for FORWARD direction

detector = vision.CascadeObjectDetector();%Detect objects using Viola Jones Algorithm, All hail MATLAB!!!
detector1 = vision.CascadeObjectDetector('EyePairSmall');%Detect a pair of eyes from the images using Viola Jones Algorithm 

while true %Infinite loop
    
    vid=snapshot(cam);%Takes the snapshot from the camera feed  
    vid = rgb2gray(vid);%converts snapshot to grayscale image to improve speed and reduce computational time 
    img = flip(vid, 2);%creates a flipped image across the y axis to check for left and right issue
    
     bbox = step(detector, img); %Compute and returns statistics of input binary image
      
     if ~ isempty(bbox)   %checks for the biggest bounding box in the camera feed
         biggest_box=1;     
         for i=1:rank(bbox) 
             if bbox(i,3)>bbox(biggest_box,3)
                 biggest_box=i;
             end
         end
         faceImage = imcrop(img,bbox(biggest_box,:)); %crops the whole image to extract the face in the biggest bounding box 
         bboxeyes = step(detector1, faceImage); % check the bounding box for eyes in the face image 
         
         subplot(2,2,1),subimage(img); hold on; %plots the the camera's original feed in grayscale 
         for i=1:size(bbox,1)    
             rectangle('position', bbox(i, :), 'lineWidth', 2, 'edgeColor', 'y');
         end
         
         subplot(2,2,3),subimage(faceImage);     %plots the cropped image of face
                 
         if ~ isempty(bboxeyes)  %check for pair of eyes in the bounding box of face's cropped image
             
             biggest_box_eyes=1;     
             for i=1:rank(bboxeyes) % finds biggest possible pair of eyes
                 if bboxeyes(i,3)>bboxeyes(biggest_box_eyes,3)
                     biggest_box_eyes=i;
                 end
             end
             
             bboxeyeshalf=[bboxeyes(biggest_box_eyes,1),bboxeyes(biggest_box_eyes,2),bboxeyes(biggest_box_eyes,3)/3,bboxeyes(biggest_box_eyes,4)];   
             
             eyesImage = imcrop(faceImage,bboxeyeshalf(1,:));% extracts only one of the eyes from a pair of eyes    
             eyesImage = imadjust(eyesImage);   %adjusts image intensity value 
             eyesImage = adapthisteq(eyesImage); %CLAHE for the cropped eye image
             r = bboxeyeshalf(1,4)/4;
             [centers, radii, metric] = imfindcircles(eyesImage, [floor(r-r/4) floor(r+r/2)], 'ObjectPolarity','dark', 'Sensitivity', 0.94); %using Hough trasform to find the centre of the eye's pupil
             [M,I] = sort(radii, 'descend');
                 
             eyesPositions = centers;% consider the initial position of the eye to be the center
                 
             subplot(2,2,2),subimage(eyesImage); hold on;% plot the eye's image
              
             viscircles(centers, radii,'EdgeColor','b');%makes visible circles around dark objects
                  
             if ~isempty(centers)
                pupil_x=centers(1); %Function to compare previous and present images to detect the direction of gaze
                disL=abs(0-pupil_x);
                disR=abs(bboxeyes(1,3)/3-pupil_x);
                subplot(2,2,4);
                
                if disL>disR+16
                    subimage(right);
                    writeDigitalPin(a,'D8',1); %right
                    pause(0.6);
                    writeDigitalPin(a,'D8',0);
                else if disR>disL
                    subimage(left);
                    writeDigitalPin(a,'D11',1);%left
                    pause(0.6);
                    writeDigitalPin(a,'D11',0);
                    else
                       subimage(straight);
                       writeDigitalPin(a,'D10',1);% forward
                       pause(0.6);
                       writeDigitalPin(a,'D10',0);
                    end
                end
     
             end          
         end
     else
        subplot(2,2,4);
        subimage(noface);
        writeDigitalPin(a,'D9',1); %STOP
        pause(0.6);
        writeDigitalPin(a,'D9',0);
     end
     set(gca,'XtickLabel',[],'YtickLabel',[]);

   hold off;
end

