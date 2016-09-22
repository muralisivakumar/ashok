package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;


import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

public class ProductShipAdapter extends BaseAdapter 
{
	 
	 Context context;
	 ArrayList<Model5> productshippinginfo;
	
	 
	 public ProductShipAdapter(Context context, ArrayList<Model5> list) 
	 {
	 
	  this.context = context;
	  this.productshippinginfo = list;
	 }
	 
	 @Override
	 public int getCount() 
	 {
	 
	  return productshippinginfo.size();
	 }
	 
	 @Override
	 public Object getItem(int position)
	 {
	 
	  return productshippinginfo.get(position);
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
	  
	   view = inflater.inflate(R.layout.product_ship_row, null);
	 
	  }else{
		  
	  view  = convertView;
	  }
	  
	//  Model model 
	 Model5 productShipItems = productshippinginfo.get(position);
		 
	  
	 
	 TextView text1=(TextView)view.findViewById(R.id.text1);
	  TextView text2=(TextView)view.findViewById(R.id.text2);
	  TextView text3=(TextView)view.findViewById(R.id.text3);
	  TextView text4=(TextView)view.findViewById(R.id.text4);
	  TextView text5=(TextView)view.findViewById(R.id.text5);
	  TextView text6=(TextView)view.findViewById(R.id.text6);
	  TextView text7=(TextView)view.findViewById(R.id.text7);
	  TextView text8=(TextView)view.findViewById(R.id.text8);
	  TextView text9=(TextView)view.findViewById(R.id.text9);
	  
	  
	  
	      text1.setText(productShipItems.getPid());
	     text2.setText(productShipItems.getPname());
	     text3.setText(productShipItems.getPurchasedate());
	     text4.setText(productShipItems.getAddressid());
	     text5.setText(productShipItems.getAdresspid());
	     text6.setText(productShipItems.getStreet());
	     text7.setText(productShipItems.getShippingdate());
	     text8.setText(productShipItems.getMobile());
	     text9.setText(productShipItems.getEmail());
	     
	   
	 
  
	  
	return view;
	 }


}
