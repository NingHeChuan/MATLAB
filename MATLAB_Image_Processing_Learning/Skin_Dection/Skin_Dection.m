clc;
clear all;
close all;

RGB_data = imread('xue.jpg');%图像读入

R_data =    RGB_data(:,:,1);
G_data =    RGB_data(:,:,2);
B_data =    RGB_data(:,:,3);

%imshow(RGB_data);

[ROW,COL, DIM] = size(RGB_data); %提取图片的行列数

Y_data = zeros(ROW,COL);
Cb_data = zeros(ROW,COL);
Cr_data = zeros(ROW,COL);
Gray_data = zeros(ROW,COL);

YCbCr_data = rgb2ycbcr(RGB_data);

Y_data = YCbCr_data(:,:,1);
Cb_data = YCbCr_data(:,:,2);
Cr_data = YCbCr_data(:,:,3);

 for r = 1:ROW
     for c = 1:COL
         if(Cb_data(r, c) > 77 && Cb_data(r, c) < 127 && Cr_data(r, c) > 133 && Cr_data(r, c) < 173)
             Gray_data(r, c) = 255;
         else
             Gray_data(r, c) = 0;
         end
     end
 end
 
% figure;
% imshow(YCbCr_data);

figure;
imshow(Gray_data);
Sobel_Img = Gray_data;

%imclose Erosion_Dilation
%Dilation
Dilation_img = zeros(ROW,COL);
for r = 2:ROW-1
    for c = 2:COL-1
		or1 = bitor(Sobel_Img(r-1, c-1), bitor(Sobel_Img(r-1, c), Sobel_Img(r-1, c+1)));
		or2 = bitor(Sobel_Img(r, c-1), bitor(Sobel_Img(r, c), Sobel_Img(r, c+1)));
		or3 = bitor(Sobel_Img(r+1, c-1), bitor(Sobel_Img(r+1, c), Sobel_Img(r+1, c+1)));
		Dilation_img(r, c) = bitor(or1, bitor(or2, or3));
    end
end

figure;
imshow(Dilation_img);

%Erosion
Erosion_img = zeros(ROW,COL);
for r = 2:ROW-1
    for c = 2:COL-1
		and1 = bitand(Dilation_img(r-1, c-1), bitand(Dilation_img(r-1, c), Dilation_img(r-1, c+1)));
		and2 = bitand(Dilation_img(r, c-1), bitand(Dilation_img(r, c), Dilation_img(r, c+1)));
		and3 = bitand(Dilation_img(r+1, c-1), bitand(Dilation_img(r+1, c), Dilation_img(r+1, c+1)));
		Erosion_img(r, c) = bitand(and1, bitand(and2, and3));
    end
end

figure;
imshow(Erosion_img);

% Skin Dection

uint16 x_min;
uint16 x_max;
uint16 y_min;
uint16 y_max;

x_min = 640;
x_max = 0;
y_min = 480;
y_max = 0;

for r = 1:ROW
    for c = 1:COL
        if(Erosion_img(r, c) > 0 && x_min > c)
            x_min = c;
        end
        if(Erosion_img(r, c) > 0 && x_max < c)
            x_max = c;
        end
        if(Erosion_img(r, c) > 0 && y_min > r)
            y_min = r;
        end
        if(Erosion_img(r, c) > 0 && y_max < r)
            y_max = r;
        end
    end
end

for r = 1:ROW
    for c = 1:COL
        if(r == y_min && c >= x_min && c <= x_max)
            img(r, c, 1) = 255;
            img(r, c, 2) = 255;
            img(r, c, 3) = 255;
        elseif(r == y_max && c >= x_min && c <= x_max)
            img(r, c, 1) = 255;
            img(r, c, 2) = 255;
            img(r, c, 3) = 255;
        elseif(c == x_min && r >= y_min && r <= y_max)
            img(r, c, 1) = 255;
            img(r, c, 2) = 255;
            img(r, c, 3) = 255;
        elseif(c == x_max && r >= y_min && r <= y_max)
            img(r, c, 1) = 255;
            img(r, c, 2) = 255;
            img(r, c, 3) = 255;
        else
            img(r, c, 1) = RGB_data(r, c, 1);
            img(r, c, 2) = RGB_data(r, c, 2);
            img(r, c, 3) = RGB_data(r, c, 3);
        end
    end
end
figure;
imshow(img);
