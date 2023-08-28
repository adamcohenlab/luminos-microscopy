#pragma once
#include "HD_Matrix.h"
class LUMINOSCONFOCAL_API HD_Grid_Data
{
public:
	HD_Grid_Data();
	HD_Grid_Data(double x_min, double x_max, double y_min, double y_max, double nx, double ny);
	~HD_Grid_Data();
	int Print_Grid();
	int Print_Values();
	int numx;
	int numy;
	double xmin;
	double xmax;
	double ymin;
	double ymax;
	double dx;
	double dy;
	HD_Matrix Data;
	HD_Matrix Weights;
	int Update_Data(double* xdata, double* ydata, double* zdata, unsigned length);
	int Update_Data_DCShift(double* xdata, double* ydata, double* zdata, unsigned length, double xshift, double yshift);

	int Set_Grid(double x_min, double x_max, double y_min, double y_max, double nx, double ny);
	int Update_Data_Simple(double* xdata, double* ydata, double* zdata, unsigned length);
};

