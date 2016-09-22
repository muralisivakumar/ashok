package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;



import android.app.Activity;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.widget.ListView;

public class ProductShippingInfo extends Activity 
{
	
	ListView list;
	SQLiteDatabase db;
	DatabaseHelper database;
	Cursor c;
	ArrayList<Model5> l1;
	String Pid,pname,purchasedate,addressid,addresspid,street,receivedtime,mobile,email;


	@Override
	protected void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_product_shipping_info);
		
		list=(ListView)findViewById(R.id.list);
		l1=new ArrayList<Model5>();
		
		database=new DatabaseHelper(this);
		db=database.getWritableDatabase();
		db=database.getReadableDatabase();
		
		String userid=getIntent().getExtras().getString("USERID");
		String pid1=getIntent().getExtras().getString("PID");
		
		System.out.println("UserId is"+userid);
		System.out.println("ProductId is"+pid1);


		c = db.rawQuery("SELECT p.PID,p.PRODUCTNAME,p.PURCHASEDATE,a.ADRESSID,a.PID,ad.STREET,a.RECEIVEDTIME,l.MOBILE,l.EMAIL FROM ActivityInfo a LEFT JOIN ProductInfo p ON a.PID==p.PID LEFT JOIN AddressInfo ad ON a.ADRESSID==ad.ADRESSID LEFT JOIN LoginInfo l ON a.USERID==l.ROWID WHERE a.USERID= '"+userid+"' AND a.PID= '"+pid1+"'",null);
		 if(c!=null)
			{
			 
			if(c.moveToFirst())
			{
				
				do {
					Model5 m=new Model5();
					 Pid=c.getString(0);
				     pname=c.getString(1);
				      purchasedate=c.getString(2);
				      addressid=c.getString(3);
				      addresspid=c.getString(4);
				      street=c.getString(5);
				     receivedtime=c.getString(6);
				      mobile=c.getString(7);
				      email=c.getString(8);
				
					 System.out.println("hi values"+"\t"+userid+"\t"+pname+"\t"+purchasedate+"\t"+addressid);
					// b1=BitmapFactory.decodeByteArray(img1, 0, img1.length);
					 
					 m.setPid("Product Id :\t"+Pid);
					 m.setPname("Product Name :\t"+pname);
					 m.setPurchasedate("Purchase Date:\t"+purchasedate);
					 m.setAddressid("Addresss Id:\t"+addressid);
					 m.setAdresspid("Address PID:\t"+addresspid);
					 m.setStreet("Address Details:\t"+street);
					 m.setShippingdate("ShippingDate:\t"+receivedtime);
					 m.setMobile("Mobile Number:\t"+mobile);
					 m.setEmail("Contact Email:\t"+email);
					 
					l1.add(m);
					
					
					
					 } while (c.moveToNext());
			}
			}
			
			for (int i = 0; i < l1.size(); i++) {
				
				System.out.println("DATAA===>"+l1.get(i).getPid()+""+l1.get(i).getPname());
			}
	 ProductShipAdapter productShipAdapter = new ProductShipAdapter(ProductShippingInfo.this, l1);
					 list.setAdapter(productShipAdapter);
					 productShipAdapter.notifyDataSetChanged();

	}

}
