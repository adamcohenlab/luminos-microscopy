#include "HD_Grid_Data.h"

HD_Grid_Data::HD_Grid_Data() {
}

HD_Grid_Data::HD_Grid_Data(double x_min, double x_max, double y_min, double y_max, double nx, double ny) :
    xmin(x_min), xmax(x_max), ymin(y_min), ymax(y_max), numx(nx), numy(ny), dx((x_max - x_min) / (nx - 1)),
    dy((y_max - y_min) / (ny - 1)), Data(ny + 1, nx + 1), Weights(ny + 1, nx + 1) {
    Weights.Fill_Zeros();
    Data.Fill_Zeros();
}

HD_Grid_Data::~HD_Grid_Data() {
}


int HD_Grid_Data::Update_Data_Simple(double* xdata, double* ydata, double* zdata, unsigned length) {
    double weight;
    double x_dist;
    double y_dist;
    unsigned flx = 0;
    unsigned fly = 0;
    int xindex = 0;
    int yindex = 0;
    Weights.Fill_Zeros();
    Data.Fill_Zeros();
    for (int i = 0; i < numy; i++) {
        for (int j = 0; j < numx; j++) {
            if ((j % 2) == 0) {
                Data(i, j) = 0;
            }
            else {
                Data(i, j) = ((double)i) / numy*10;
            }
        }
    }
    return 0;
}

int HD_Grid_Data::Update_Data_DCShift(double* xdata, double* ydata, double* zdata, unsigned length,double xshift, double yshift) {
    double weight;
    double x_dist;
    double y_dist;
    int flx = 0;
    int fly = 0;
    int xindex = 0;
    int yindex = 0;
    Weights.Fill_Zeros();
    Data.Fill_Zeros();
    for (int n = 0; n < length; n++) {
        if ((xmin <= (xdata[n]+xshift)) && (xmax >= (xdata[n]+xshift)) && (ymin <= (ydata[n]+yshift)) && (ymax >= (ydata[n]+yshift))) {
            flx = floor((xdata[n]+xshift - xmin) / dx);
            fly = floor((ydata[n]+yshift - ymin) / dy);
            fly = (fly >= 0) ? (fly) : (0);
            flx = (flx >= 0) ? (flx) : (0);
            for (xindex = 0; xindex < 2; xindex++) {
                for (yindex = 0; yindex < 2; yindex++) {
                    weight = 1 - (sqrt(pow((xdata[n]+xshift - xmin) / dx - ((xindex == 0) ? (flx) : (flx + 1)), 2) + pow((ydata[n]+yshift - ymin) / dy - ((yindex == 0) ? (fly) : (fly + 1)), 2)) / sqrt(2));
                    Data(fly + yindex, flx + xindex) = *(zdata + n) * weight + Data(fly + yindex, flx + xindex);
                    Weights(fly + yindex, flx + xindex) = Weights(fly + yindex, flx + xindex) + weight;

                }
            }
        }
        else {
            //printf("rejected point: %d \n", n);
        }
    }
    for (int i = 0; i < numy; i++) {
        for (int j = 0; j < numx; j++) {
            if (Weights(i, j) > 0) {
                Data(i, j) = Data(i, j) / Weights(i, j);
            }
        }
    }
    return 0;
}


int HD_Grid_Data::Update_Data(double* xdata, double* ydata, double* zdata, unsigned length) {
    double weight;
    double x_dist;
    double y_dist;
    unsigned flx = 0;
    unsigned fly = 0;
    int xindex = 0;
    int yindex = 0;
    Weights.Fill_Zeros();
    Data.Fill_Zeros();
    for (int n = 0; n < length; n++) {
        if ((xmin <= (xdata[n])) && (xmax >= (xdata[n])) && (ymin <= (ydata[n])) && (ymax >= (ydata[n]))) {
            flx = floor((xdata[n] - xmin) / dx);
            fly = floor((ydata[n] - ymin) / dy);
            for (xindex = 0; xindex < 2; xindex++) {
                for (yindex = 0; yindex < 2; yindex++) {
                    weight = 1 - (sqrt(pow((xdata[n]-xmin) / dx - ((xindex == 0) ? (flx) : (flx + 1)), 2) + pow((ydata[n]-ymin) / dy - ((yindex == 0) ? (fly) : (fly + 1)), 2)) / sqrt(2));
                    Data(fly + yindex, flx + xindex) = *(zdata + n) * weight + Data(fly + yindex, flx + xindex);
                    Weights(fly + yindex, flx + xindex) = Weights(fly + yindex, flx + xindex) + weight;

                }
            }
        }
        else {
            //printf("rejected point: %d \n", n);
        }
    }
    for (int i = 0; i < numy; i++) {
        for (int j = 0; j < numx; j++) {
            if (Weights(i, j) > 0) {
                Data(i, j) = Data(i, j) / Weights(i, j);
            }
        }
    }
    return 0;
}

int HD_Grid_Data::Print_Grid() {
    double xval = 0;
    double yval = 0;
    for (int ii = 0; ii < numy; ii++) {
        for (int jj = 0; jj < numx; jj++) {
            xval = jj * dx + xmin;
            yval = ii * dy + ymin;
            printf("%f , %f \t", yval, xval);
        }
        printf("\n");
    }
    return 0;
}

int HD_Grid_Data::Print_Values() {
    double xval = 0;
    double yval = 0;
    for (int ii = 0; ii < numy; ii++) {
        for (int jj = 0; jj < numx; jj++) {
            printf("%f \t", Data(ii,jj));
        }
        printf("\n");
    }
    return 0;
}


int HD_Grid_Data::Set_Grid(double x_min, double x_max, double y_min, double y_max, double nx, double ny) {
    xmin = x_min;
    xmax = x_max;
    ymin = y_min;
    ymax = y_max;
    numx = nx;
    numy = ny;
    dx = (xmax - xmin) / nx;
    dy = (ymax - ymin) / ny;
    Data.resize(numy+1, numx+1);
    Weights.resize(numy+1, numx+1);
    return 0;
}

