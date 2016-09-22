package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;


import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ListView;

public class ViewPage extends Activity 
{
	SQLiteDatabase db;
	DatabaseHelper database;
	ListView list;
	//String name,mail,phonenumber;
	ArrayList<Model> l1;
	byte[] img1;
	Bitmap b1;
	Cursor c;

	
	@Override
	protected void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_view_page);
		list=(ListView)findViewById(R.id.list);
		l1=new ArrayList<Model>();
       
	

		database=new DatabaseHelper(this);
		db=database.getWritableDatabase();
		db=database.getReadableDatabase();


		 c = db.rawQuery("SELECT IMAGE,USERNAME,EMAIL,MOBILE from LoginInfo", null);  
		 
		if(c!=null)
		{
		 
		if(c.moveToFirst())
		{
			
			do {
				Model m=new Model();
			 String	 name=c.getString(1);
			 String	 mail=c.getString(2);
			 String	 phonenumber=c.getString(3);
			 byte[]	 img1=c.getBlob(0);
				 System.out.println("hi values"+"\t"+name+"\t"+mail+"\t"+phonenumber+"\t"+img1);
				// b1=BitmapFactory.decodeByteArray(img1, 0, img1.length);
				 
				 m.setImage(img1);
				 m.setName(name);
				 m.setMail(mail);
				 m.setPhone(phonenumber);
				 
				l1.add(m);
				// l1.add(phonenumber);
				
				
				 } while (c.moveToNext());
		}
		}
		
		for (int i = 0; i < l1.size(); i++) {
			
			System.out.println("DATAA===>"+l1.get(i).getMail()+""+l1.get(i).getName());
		}
 ContactListAdapter contactListAdapter = new ContactListAdapter(ViewPage.this, l1);
				 list.setAdapter(contactListAdapter);
				 contactListAdapter.notifyDataSetChanged();
		
	list.setOnItemClickListener(new OnItemClickListener() 
	{

		@Override
		public void onItemClick(AdapterView<?> arg0, View arg1, int pos,long arg3) 
		{
			// TODO Auto-generated method stub
			Intent displaydetails=new Intent(ViewPage.this, DisplayDetailsOne.class);
			displaydetails.putExtra("Position", pos);
			startActivity(displaydetails);
			
		}
	});
	} 
	}
	
	
	

