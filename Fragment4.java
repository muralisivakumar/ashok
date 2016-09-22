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



public class Fragment4 extends Fragment
{
	
	SQLiteDatabase db;
	DatabaseHelper database;
	ListView list;
	ArrayList<Model2> l1;
	
	Cursor c;
	public Fragment4(){}
	
	@Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,Bundle savedInstanceState) 
	{
		//This method having the Benefits data
		//BenefitsData();
        View rootView = inflater.inflate(R.layout.activity_view_page, container, false);
       

        list=(ListView)rootView.findViewById(R.id.list);
		l1=new ArrayList<Model2>();
       

		database=new DatabaseHelper(getActivity());
		db=database.getWritableDatabase();
		db=database.getReadableDatabase();


		 c = db.rawQuery("SELECT * from ActivityInfo", null);  
		 
		if(c!=null)
		{
		 
		if(c.moveToFirst())
		{
			
			do {
				Model2 m=new Model2();
			 String	 rowid=c.getString(0);
			 String	 userid=c.getString(1);
			 String	 pid=c.getString(2);
			 String addressid=c.getString(3);
			 String	 shipdate=c.getString(4);
				 System.out.println("hi values"+"\t"+rowid+"\t"+userid+"\t"+pid+"\t"+shipdate);
				// b1=BitmapFactory.decodeByteArray(img1, 0, img1.length);
				 
			
				 m.setRowId(rowid);
				 m.setUserId(userid);
				 m.setPId(pid);
				 m.setAddId(addressid);
				 m.setShipDate(shipdate);
				 
				l1.add(m);
				

				 } while (c.moveToNext());
		}
		}
		
		for (int i = 0; i < l1.size(); i++) 
		{
			
			System.out.println("DATAA===>"+l1.get(i).getRowId()+""+l1.get(i).getShipDate());
		}
 ActivityListAdapter activityListAdapter = new ActivityListAdapter(getActivity(), l1);
				 list.setAdapter(activityListAdapter);
				 activityListAdapter.notifyDataSetChanged();
				 return rootView;
		
	}
	
	}

