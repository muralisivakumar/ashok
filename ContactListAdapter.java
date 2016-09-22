package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.TextView;


public class ContactListAdapter extends BaseAdapter {
	 
	 Context context;
	 ArrayList<Model> contactList;
	 byte[] img1;
	 Bitmap b1;
	 
	 public ContactListAdapter(Context context, ArrayList<Model> list) {
	 
	  this.context = context;
	  this.contactList = list;
	 }
	 
	 @Override
	 public int getCount() {
	 
	  return contactList.size();
	 }
	 
	 @Override
	 public Object getItem(int position)
	 {
	 
	  return contactList.get(position);
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
	  
	   view = inflater.inflate(R.layout.contact_list_row, null);
	 
	  }else{
		  
	  view  = convertView;
	  }
	  
	//  Model model 
	 Model contactListItems = contactList.get(position);
		 
	  img1=contactListItems.getImage();
	  b1=BitmapFactory.decodeByteArray(img1, 0, img1.length);
	  ImageView img=(ImageView)view.findViewById(R.id.image);
	  img.setImageBitmap(b1);
	 TextView text1=(TextView)view.findViewById(R.id.text1);
	  TextView text2=(TextView)view.findViewById(R.id.text2);
	  TextView text3=(TextView)view.findViewById(R.id.text3);
	 text1.setText(contactListItems.getName());
	 text2.setText(contactListItems.getMail());
	 text3.setText(contactListItems.getPhone());
	  
	 
	
     
	 
	  return view;
	 }
	 
	}