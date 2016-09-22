package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;


import android.content.Context;
import android.graphics.Bitmap;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

public class ActivityListAdapter extends BaseAdapter {
		 
		 Context context;
		 ArrayList<Model2> activityList;
		 byte[] img1;
		 Bitmap b1;
		 
		 public ActivityListAdapter(Context context, ArrayList<Model2> list) {
		 
		  this.context = context;
		  this.activityList = list;
		 }
		 
		 @Override
		 public int getCount() {
		 
		  return activityList.size();
		 }
		 
		 @Override
		 public Object getItem(int position)
		 {
		 
		  return activityList.get(position);
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
		  
		   view = inflater.inflate(R.layout.activity_list_row, null);
		 
		  }else{
			  
		  view  = convertView;
		  }
		  
		//  Model model 
		 Model2 activityListItems = activityList.get(position);
		
		 TextView text1=(TextView)view.findViewById(R.id.text1);
		  TextView text2=(TextView)view.findViewById(R.id.text2);
		  TextView text3=(TextView)view.findViewById(R.id.text3);
		  TextView text4=(TextView)view.findViewById(R.id.text4);
		  TextView text5=(TextView)view.findViewById(R.id.text5); 
		  
		  text1.setText(activityListItems.getRowId());
		 text2.setText(activityListItems.getUserId());
		 text3.setText(activityListItems.getPId());
		 text4.setText(activityListItems.getAddId());
		 text5.setText(activityListItems.getShipDate());
		  
		 
		 return view;
		 }
		 
}
