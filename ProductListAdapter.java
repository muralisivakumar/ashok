package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

public class ProductListAdapter extends BaseAdapter 
{
	 
	 Context context;
	 ArrayList<Model3> productList;
	
	 
	 public ProductListAdapter(Context context, ArrayList<Model3> list) 
	 {
	 
	  this.context = context;
	  this.productList = list;
	 }
	 
	 @Override
	 public int getCount() 
	 {
	 
	  return productList.size();
	 }
	 
	 @Override
	 public Object getItem(int position)
	 {
	 
	  return productList.get(position);
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
	  
	   view = inflater.inflate(R.layout.product_list_row, null);
	 
	  }else{
		  
	  view  = convertView;
	  }
	  
	//  Model model 
	 Model3 productListItems = productList.get(position);
		 
	  
	 
	 TextView text1=(TextView)view.findViewById(R.id.text1);
	  TextView text2=(TextView)view.findViewById(R.id.text2);
	  TextView text3=(TextView)view.findViewById(R.id.text3);
	  TextView text4=(TextView)view.findViewById(R.id.text4);
	  TextView text5=(TextView)view.findViewById(R.id.text5);
	  TextView text6=(TextView)view.findViewById(R.id.text6);
	  TextView text7=(TextView)view.findViewById(R.id.text7);
		 
	  
	     text5.setText(productListItems.getAddressPid());
		 text4.setText(productListItems.getAddressId());
	     text6.setText(productListItems.getStreet());
	     text7.setText(productListItems.getShippingDate());
	     text1.setText(productListItems.getProductPid());
	     text2.setText(productListItems.getProductName());
	     text3.setText(productListItems.getPurchaseDate());
	   
   
	  
	return view;
	 }
	 

}
