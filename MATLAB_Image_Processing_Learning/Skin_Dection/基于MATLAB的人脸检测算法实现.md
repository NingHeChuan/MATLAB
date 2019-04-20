# 【狗头】基于薛兆丰老师的人脸检测

> 没有对薛兆丰老师产生不敬，因为薛老师这张图片面部肤色和身体背景等颜色差异明显，所以比较适合做基于肤色模型的人脸检测。热巴、娜扎、超越等人的图片都漏肩膀漏脖子的，干扰太大。

基于MATLAB的人脸检测算法实现，后面再将算法用Verilog实现，这是我做FPGA进行图像处理的最后一站，后面要去学习其他内容。做了一些基础的图像处理算法，感觉是在实现上很多方法都是类似的，更重要的是理论的学习。博主后面打算为后面的工作做些基础知识的储备，图像处理的内容就到此为止。

![image](https://wx4.sinaimg.cn/large/006C4SD7ly1g0uflxi6lnj30k20b40vq.jpg)

整个设计人脸检测一共分为以下几步

- RGB到YCbCr色彩空间转换
- Cb、Cr阈值分离肤色二值化
- 先膨胀后腐蚀（闭运算）
- 人脸区域框选

#### 肤色识别

本设计是基于肤色模型的人脸检测，简单来说就是通过皮肤的颜色来判断图片中你脸的为止，一副图片有RGB三分量的颜色组成，将RGB色彩空间转换成YCbCr色彩空间上，肤色的判断就可以用Cb和Cr分量的阈值来判断。

肤色识别YCbCr阈值

77 < Cb < 127

133 < Cr < 173

关于RGB2YCbCr色彩空间的转换我之前有发过文章[基于MATLAB的RGB转YCBCR色彩空间转换](https://www.cnblogs.com/ninghechuan/p/9515639.html)，这里直接用的是MATLAB自带的函数，因为系数的一些问题，上FPGA实测是没有问题的。

这种基于肤色的识别比较粗糙，这个阈值只能识别黄种人，而且只要是皮肤，甚至是黄颜色的笔记本，都能被区分出来，这就回到了开始为什么说不能用小姐姐们，因为小姐姐的大白胳膊会影响效果。。不过鉴于日常我们都穿着衣装，只露个脸的话还是可以达到终极目标的。

#### 闭运算

![image](https://wx2.sinaimg.cn/large/006C4SD7ly1g0uflxo7itj30k20b43yh.jpg)

上图为阈值分割后再进行闭运算的效果。

先腐蚀后膨胀叫开运算，开运算的作用是清除图像边缘周围非边缘的细小的点。先膨胀后腐蚀为闭运算，闭运算的作用是清除图像内部的空洞，

如果我们的目标物体外面有很多无关的小区域，就用开运算去除掉；如果物体内部有很多小黑洞，就用闭运算填充掉。

#### 人脸框选

![image](https://wx4.sinaimg.cn/large/006C4SD7ly1g0uflxlrz5j30k20b4whh.jpg)

经过闭运算后，可以看到面部区域和身体背景已经区分出来。现在只需要画一个框将图中白色区域框起来。从第一个点开始逐行遍历所有点，根据像素值为不为0（即全1），找到整个人脸边框的四个顶点。

然后根据四个顶点的位置画出整个人脸的区域。具体代码实现也是比较好理解的，直接看代码吧！



#### MATLAB代码

```matlab
clc;
clear all;
close all;

RGB_data = imread('reba.jpg');%图像读入
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
```



```verilog
$display("点个好看吧！");
```



![image](https://ws1.sinaimg.cn/large/006C4SD7gy1fxd6btvu5vj30kk0b9taw.jpg)

![image](https://wx3.sinaimg.cn/large/006C4SD7gy1fxyapnjoh1j30gb0gstaq.jpg)