package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;

import android.app.Activity;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.widget.ListView;

public class ViewProductAddress extends Activity 
{

	Cursor c;
	SQLiteDatabase db;
	DatabaseHelper database;
	String UserId;
	 SharedPreferences sh_Pref;
	ListView list;
	ArrayList<Model3> l1;
	@Override
	protected void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_view_product_address);
		
		
		list=(ListView)findViewById(R.id.list);
		l1=new ArrayList<Model3>();
		
		database=new DatabaseHelper(this);
		db=database.getWritableDatabase();
		db=database.getReadableDatabase();
		
		UserId = getIntent().getExtras().getString("USERID");
         
		System.out.println("UserID is:\t"+UserId);
	    
          c=db.rawQuery("SELECT P.PID,P.PRODUCTNAME,P.PURCHASEDATE,A.ADRESSID,A.PID,A.STREET,A.SHIPPINGDATE FROM ProductInfo P LEFT JOIN AddressInfo A ON P.PID=A.PID  WHERE P.PID='"+UserId+"'",null);
	
	     if(c!=null)
			{
			 
			if(c.moveToFirst())
			{
				
				do {
					Model3 m=new Model3();
				 String	 productid=c.getString(0);
				 String	 productname=c.getString(1);
				 String	 purchasedate=c.getString(2);
				 String addressid=c.getString(3);
				 String	 adressproductid=c.getString(4);
				 String	street=c.getString(5);
				 String	 shipdate=c.getString(6);
					 System.out.println("hi values"+"\t"+productid+"\t"+productname+"\t"+purchasedate+"\t"+addressid+"\t"+shipdate);
			
					 
				
	                m.setProductPid(productid);
	                m.setProductName(productname);
	                m.setPurchaseDate(purchasedate);
	                m.setAddressId(addressid);
	                m.setAddressPid(adressproductid);
	                m.setStreet(street);
	                m.setShippingDate(shipdate);
					 
					l1.add(m);
					

					 } while (c.moveToNext());
			}
			}
			
			for (int i = 0; i < l1.size(); i++) {
				
				System.out.println("DATAA===>"+l1.get(i).getProductPid()+""+l1.get(i).getProductName());
			}
	ProductListAdapter productListAdapter = new ProductListAdapter(ViewProductAddress.this, l1);
					 list.setAdapter(productListAdapter);
					 productListAdapter.notifyDataSetChanged();
	
	
	}

}
