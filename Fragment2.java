package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;

import android.app.Fragment;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ListView;

public class Fragment2 extends Fragment 
{
	ListView list;
	SQLiteDatabase db;
	DatabaseHelper database;
	Cursor c,c1;
	ArrayList<Model4> l1;
    String pid,pname,purchasedate,userid1,pid1;
	public Fragment2(){}
	
	@Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,Bundle savedInstanceState) 
	{
		//This method having the Benefits data
		//BenefitsData();
        View rootView = inflater.inflate(R.layout.activity_product_details, container, false);
        list=(ListView)rootView.findViewById(R.id.list);
		l1=new ArrayList<Model4>();
		
		database=new DatabaseHelper(getActivity());
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
	 ProductInfoAdapter productListAdapter = new ProductInfoAdapter(getActivity(), l1);
					 list.setAdapter(productListAdapter);
					 productListAdapter.notifyDataSetChanged();
        return rootView;
	}
}