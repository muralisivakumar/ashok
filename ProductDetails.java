package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;


import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ListView;

public class ProductDetails extends Activity 
{

	ListView list;
	SQLiteDatabase db;
	DatabaseHelper database;
	Cursor c,c1;
	ArrayList<Model4> l1;
    String pid,pname,purchasedate,userid1,pid1;
	@Override
	protected void onCreate(Bundle savedInstanceState)
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_product_details);

		list=(ListView)findViewById(R.id.list);
		l1=new ArrayList<Model4>();
		
		database=new DatabaseHelper(this);
		db=database.getWritableDatabase();
		db=database.getReadableDatabase();
		 c = db.rawQuery("SELECT * from ProductInfo", null);
		 
		 if(c!=null)
			{
			 
			if(c.moveToFirst())
			{
				
				do {
					Model4 m=new Model4();
		       pid=c.getString(0);
				pname=c.getString(1);
				 purchasedate=c.getString(2);
				
					 System.out.println("hi values"+"\t"+pid+"\t"+pname+"\t"+purchasedate);
					// b1=BitmapFactory.decodeByteArray(img1, 0, img1.length);
					 
					 m.setPid("Product Id:\t"+pid);
					 m.setPnme("Product name:\t"+pname);
					 m.setPurchasedate("Purchase Date:\t"+purchasedate);
		
					 
					l1.add(m);
					
					
					
					 } while (c.moveToNext());
			}
			}
			
			for (int i = 0; i < l1.size(); i++) {
				
				System.out.println("DATAA===>"+l1.get(i).getPid()+""+l1.get(i).getPnme());
			}
	 ProductInfoAdapter productListAdapter = new ProductInfoAdapter(ProductDetails.this, l1);
					 list.setAdapter(productListAdapter);
					 productListAdapter.notifyDataSetChanged();
			
		list.setOnItemClickListener(new OnItemClickListener() 
		{

			@Override
			public void onItemClick(AdapterView<?> arg0, View arg1, int pos,long arg3) 
			{
				// TODO Auto-generated method stub
				
				Intent displaydetails=new Intent(ProductDetails.this, ProductShippingInfo.class);
				
				System.out.println("the position is:"+pos);
				int position=pos+1;
				
				c = db.rawQuery("SELECT a.USERID,p.PID FROM ActivityInfo a LEFT JOIN ProductInfo p ON a.PID==p.PID WHERE a.PID= '"+position+"'", null);
				 
				 if(c!=null)
					{
					 
					if(c.moveToFirst())
					{
						
						do {
							
				       userid1=c.getString(0);
				       pid1=c.getString(1);
						}while (c.moveToNext());
					}
				
					}
				
				displaydetails.putExtra("USERID",userid1);
				displaydetails.putExtra("PID",pid1);
				
				System.out.println("the intent UserID value is:"+userid1);
				startActivity(displaydetails);
				
			}
		});
	}

}
