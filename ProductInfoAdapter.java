package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;



import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

public class ProductInfoAdapter extends BaseAdapter 
	{
		 
		 Context context;
		 ArrayList<Model4> productinfo;
		
		 
		 public ProductInfoAdapter(Context context, ArrayList<Model4> list) 
		 {
		 
		  this.context = context;
		  this.productinfo = list;
		 }
		 
		 @Override
		 public int getCount() 
		 {
		 
		  return productinfo.size();
		 }
		 
		 @Override
		 public Object getItem(int position)
		 {
		 
		  return productinfo.get(position);
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
		  
		   view = inflater.inflate(R.layout.product_info_row, null);
		 
		  }else{
			  
		  view  = convertView;
		  }
		  
		//  Model model 
		 Model4 productItems = productinfo.get(position);
			 
		  
		 
		 TextView text1=(TextView)view.findViewById(R.id.text1);
		  TextView text2=(TextView)view.findViewById(R.id.text2);
		  TextView text3=(TextView)view.findViewById(R.id.text3);
		  
		  text1.setText(productItems.getPid());
		     text2.setText(productItems.getPnme());
		     text3.setText(productItems.getPurchasedate());
		   
		 
	   
		  
		return view;
		 }
}
