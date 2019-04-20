
%%
%编写一个基于YCbCr色彩空间的肤色分割程序
%YCbCr是DVD、摄像机、数字电视等消费类视频产品中常用的色彩编码方案
%YCbCr在模拟分量视频(analog component video)中也被常称为YPbPr
%常见的3个基本色彩模型是RGB、CMYK、YUV
%YCbCr其中Y是指亮度分量，Cb指蓝色色度分量，而Cr指红色色度分量
 
%YCbCr与RGB的相互转换 来自baidu
%Y=0.299R+0.587G+0.114B
%Cb=0.564(B-Y)
%Cr=0.713(R-Y)
%R=Y+1.402Cr
%G=Y-0.344Cb-0.714Cr
%B=Y+1.772Cb
 
%来自 wiki
%YPbPr (analog version of Y'CbCr) from R'G'B'
%Y' =  Kr * R' + (1 - Kr - Kb) * G' + Kb * B'
%Pb = 0.5 * (B' - Y') / (1 - Kb)
%Pr = 0.5 * (R' - Y') / (1 - Kr)
....................................................
%R', G', B' in [0; 1]
%Y' in [0; 1]
%Pb in [-0.5; 0.5]
%Pr in [-0.5; 0.5]
 
%人脸检测算法：
%1.精确定位人脸检测候选区
%2.验证已侦测人脸候选区的面部特征
%先要估算和纠正基于光补偿技术的肤色模型，在进行色彩空间的非线性转换
%空间转换的椭圆肤色模型，参数式的椭圆就相当于假设的肤色高斯分布下的马氏距离常数
%检测到得肤色像素被反复的分割成局部颜色变化来连接基于这些部分的空间排列和类似他们颜色人脸候选区
%候选出来的大小能在13*13的像素和大约是输入图像大小的3/4之间变动。
%面部特征检测模块抑制了不包括任何面部特征
 
%Color Image --> Lighting Compensation --> Color Space Transformation
%--> Skin Color Detection --> Variance-based Segmentation --> 
%Connected Component & Grouping --> Eye/Mouth Detection --> 
%Face Boundary Detection --> Verifying/Weighting Eyes-Mouth Triangles
 
%%
%basic operation
clc;
clear all;
close all;
 
img = imread('reba.jpg');
figure ;imshow(img);title('原始图像');
 
[row col dim] = size(img);
img_double = double(img);
 
%get RGB channel
R = img_double(:,:,1);G = img_double(:,:,2);B = img_double(:,:,3);
figure ;
subplot(1,3,1);imshow(uint8(R));title('红色分量');
subplot(1,3,2);imshow(uint8(G));title('绿色分量');
subplot(1,3,3);imshow(uint8(B));title('蓝色分量');
 
%%
%convert RGB space to YcbCr-color space
R = double(R);G = double(G);B = double(B);
H =[65.4810  128.5530   24.9660;
    -37.7970  -74.2030  112.0000;
    112.0000  -93.7860  -18.2140];
% I = H/(sum(sum(H)));%按照常规进行矩阵的归一化
I = H/255;%颜色像素空间的标准归一化
Ymax = 235;Ymin = 16;
img_YCbCr(:,:,1) = I(1,1)*R+I(1,2)*G+I(1,3)*B+16;
img_YCbCr(:,:,2) = I(2,1)*R+I(2,2)*G+I(2,3)*B+128;
img_YCbCr(:,:,3) = I(3,1)*R+I(3,2)*G+I(3,3)*B+128;
 
if(img_YCbCr(:,:,1) > Ymax)
     img_YCbCr(:,:,1) = Ymax;
elseif(img_YCbCr(:,:,1)<Ymin)
        img_YCbCr(:,:,1)=Ymin;
end
if(img_YCbCr(:,:,2) > Ymax)
     img_YCbCr(:,:,2) = Ymax;
elseif(img_YCbCr(:,:,2)<Ymin)
        img_YCbCr(:,:,2)=Ymin;
end
if(img_YCbCr(:,:,3) > Ymax)
     img_YCbCr(:,:,3) = Ymax;
elseif(img_YCbCr(:,:,3)<Ymin)
        img_YCbCr(:,:,3)=Ymin;
end
 
%%
%在YCbCr色彩空间里做肤色检测，椭圆模型检测Cb和Cr
y=img_YCbCr(:,:,1);
Cx = 109.38;Cy = 152.02;theta = 2.53;
ecx = 1.60;ecy = 2.41;a = 25.39;b = 14.03;
img_bin = zeros(row,col);
for i=1:row
    for j=1:col
        temp=cos(theta)*(img_YCbCr(i, j, 2) - Cx)+...
            sin(theta)*(img_YCbCr(i, j, 3) - Cy);
        y(i,j)=-sin(theta)*(img_YCbCr(i, j, 2) - Cx)+...
            cos(theta)*(img_YCbCr(i, j, 3) - Cy);
        lea = (temp - ecx).^2 / (a^2) + (y(i, j) - ecy).^2 / (b^2);
        if(lea<=1)   %将可能为肤色的点标记为白色
            img_bin(i,j) = 255;
        end
        if(img_YCbCr(i,j,1) <= 80) %去除图像中色彩很暗的点
            img_bin(i,j) = 0;
        end
    end
end
 
%%
%show image
img_YCbCr = uint8(img_YCbCr);
figure ;imshow(img_YCbCr);title('YCBCR模型');
figure ;
subplot(1,3,1);imshow(img_YCbCr(:,:,1));title('Y分量');
subplot(1,3,2);imshow(img_YCbCr(:,:,2));title('CB分量');
subplot(1,3,3);imshow(img_YCbCr(:,:,3));title('CR分量');
figure ;imshow(img_bin);title('分割');
 
%用3*3模板对二值图像进行膨胀操作
se = strel('diamond', 3);
img_bin = imdilate(img_bin, se);
figure ;
subplot(3,2,1);imshow(img_bin);title('diamond-膨胀');
se = strel('square', 3);
img_bin = imdilate(img_bin, se);
subplot(3,2,2);imshow(img_bin);title('square-膨胀');
se = strel('pair', [1,1]);
img_bin = imdilate(img_bin, se);
subplot(3,2,3);imshow(img_bin);title('pair-膨胀');
se = strel('disk', 3);
img_bin = imdilate(img_bin, se);
subplot(3,2,4);imshow(img_bin);title('disk-膨胀');
se = strel('rectangle', [1,3]);
img_bin = imdilate(img_bin, se);
subplot(3,2,5);imshow(img_bin);title('rectangle-膨胀');
se = strel('octagon', 3);
img_bin = imdilate(img_bin, se);
subplot(3,2,6);imshow(img_bin);title('octagon-膨胀');
