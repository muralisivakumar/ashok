package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;

import android.content.Context;
import android.graphics.Bitmap;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;



public class SalaryListAdapter extends BaseAdapter 
{
	 
	 Context context;
	 ArrayList<Model1> salaryList;
	 byte[] img1;
	 Bitmap b1;
	 
	 public SalaryListAdapter(Context context, ArrayList<Model1> list) {
	 
	  this.context = context;
	  this.salaryList = list;
	 }
	 
	 @Override
	 public int getCount() 
	 {
	 
	  return salaryList.size();
	 }
	 
	 @Override
	 public Object getItem(int position)
	 {
	 
	  return salaryList.get(position);
	 }
	 
	 @Override
	 public long getItemId(int position) 
	 {
	 
	  return position;
	 }
	 
	 @Override
	 public View getView(int position, View convertView, ViewGroup arg2) 
	 {

	View view;
	 LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
	
	  if (convertView == null)
	  {
	  
	   view = inflater.inflate(R.layout.salary_list_row, null);
	 
	  }else{
		  
	  view  = convertView;
	  }
	  
	//  Model model 
	 Model1 salaryListItems = salaryList.get(position);
		 
	  
	 
	 TextView text1=(TextView)view.findViewById(R.id.text1);
	  TextView text2=(TextView)view.findViewById(R.id.text2);
	  TextView text3=(TextView)view.findViewById(R.id.text3);
		 text1.setText(salaryListItems.getName());
	     text2.setText(salaryListItems.getSalary());
	     text3.setText(salaryListItems.getMonth());

	  
	return view;
	 }
	 
	}


