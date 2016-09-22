package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;


import android.app.Fragment;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ListView;

public class Fragment3 extends Fragment 
{
	Cursor c;
	SQLiteDatabase db;
	DatabaseHelper database;

	ListView list;
	ArrayList<Model3> l1;
	public Fragment3()
	{
		
	}
	
	@Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,Bundle savedInstanceState) 
	{
		//This method having the Benefits data
		//BenefitsData();
        View rootView = inflater.inflate(R.layout.activity_view_product_address, container, false);
        list=(ListView)rootView.findViewById(R.id.list);
		l1=new ArrayList<Model3>();
		
		database=new DatabaseHelper(getActivity());
		db=database.getWritableDatabase();
		db=database.getReadableDatabase();
		
		
         

	    
          c=db.rawQuery("SELECT A.ADRESSID,A.PID,A.STREET,A.SHIPPINGDATE FROM AddressInfo A",null);
	
	     if(c!=null)
			{
			 
			if(c.moveToFirst())
			{
				
				do {
					Model3 m=new Model3();
				 
				 String addressid=c.getString(0);
				 String	 adressproductid=c.getString(1);
				 String	street=c.getString(2);
				 String	 shipdate=c.getString(3);
					 System.out.println("hi values"+"\t"+addressid+"\t"+adressproductid+"\t"+street+"\t"+shipdate);
			
					 
				
	                
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
	ProductListAdapter productListAdapter = new ProductListAdapter(getActivity(), l1);
					 list.setAdapter(productListAdapter);
					 productListAdapter.notifyDataSetChanged();
	
        return rootView;
	}
}
