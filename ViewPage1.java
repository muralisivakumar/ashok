package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.Toast;

public class ViewPage1 extends Activity 
{

	SQLiteDatabase db;
	DatabaseHelper database;
	ListView list;
	Cursor c,c1;
	Button search;
	ArrayList<Model1> l1;
	SalaryListAdapter salaryListAdapter; 
	String Username,Month,fromsalary,tosalary;
	String WHERE="";
	
	public static final String USERNAME="Enter UserName";
	public static final String MONTH="Enter the Month";
	public static final String FROM="Enter Starting Salary";
	public static final String TO="Enter Ending Salary";
	
	@Override
	protected void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_view_page1);
		
		search=(Button)findViewById(R.id.button);

		list=(ListView)findViewById(R.id.list);
		l1=new ArrayList<Model1>();
       
	

		database=new DatabaseHelper(this);
		db=database.getWritableDatabase();
		db=database.getReadableDatabase();


		 c = db.rawQuery("SELECT LoginInfo.USERNAME,SalaryInfo.SALARY,SalaryInfo.MONTH from LoginInfo INNER JOIN SalaryInfo WHERE LoginInfo.ROWID==SalaryInfo.USERID", null);  
		 
		if(c!=null)
		{
		 
		if(c.moveToFirst())
		{
			
			do
			{
				Model1 m1=new Model1();
			 String	 salary=c.getString(1);
			 String	 month=c.getString(2);
			 String	 name=c.getString(0);
			
				 System.out.println("hi values"+"\t"+salary+"\t"+month+"\t"+name);
				// b1=BitmapFactory.decodeByteArray(img1, 0, img1.length);
				 
				 m1.setName(name);
				 m1.setSalary(salary);
				 m1.setMonth(month);
				
				 
				l1.add(m1);
			
				} while (c.moveToNext());
		}
		}
		
for (int i = 0; i < l1.size(); i++) {
			
			System.out.println("DATAA===>"+l1.get(i).getSalary()+""+l1.get(i).getMonth());
		}
salaryListAdapter = new SalaryListAdapter(ViewPage1.this, l1);
				 list.setAdapter(salaryListAdapter);
				 salaryListAdapter.notifyDataSetChanged();
		
	list.setOnItemClickListener(new OnItemClickListener() 
	{

		@Override
		public void onItemClick(AdapterView<?> arg0, View arg1, int pos,long arg3) 
		{
			// TODO Auto-generated method stub
			Toast.makeText(ViewPage1.this, "u have selected the row is"+pos, Toast.LENGTH_SHORT).show();
			
		}
	});
	search.setOnClickListener(new OnClickListener() 
	{
		
		@Override
		public void onClick(View arg0) 
		{
			// TODO Auto-generated method stub
			
			
			l1.clear();
        	salaryListAdapter.notifyDataSetChanged();
        	  
			AlertDialog.Builder alert = new AlertDialog.Builder(ViewPage1.this);

	        alert.setTitle("Enter values To Search");
	        alert.setMessage("Enter User Values");

	        // Set an EditText view to get user input 
	        final EditText uname = new EditText(ViewPage1.this);
	        uname.setHint(USERNAME);
	        final EditText month= new EditText(ViewPage1.this);
	      month.setHint(MONTH);
	        LinearLayout layout = new LinearLayout(getApplicationContext());
	        layout.setOrientation(LinearLayout.VERTICAL);
	        layout.addView(uname);
	        layout.addView(month);
	        alert.setView(layout);

	        final EditText from = new EditText(ViewPage1.this);
	        from.setHint(FROM);
	        final EditText to= new EditText(ViewPage1.this);
	         to.setHint(TO);
	         layout.addView(from);
		        layout.addView(to);
		        alert.setView(layout);

	        alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() 
	        {
	        public void onClick(DialogInterface dialog, int whichButton) 
	        {
	        	 
	              
	        	Username=uname.getText().toString();
	        	Month=month.getText().toString();
	        	fromsalary=from.getText().toString();
	        	tosalary=to.getText().toString();
	        	
	        	
	        String query="SELECT l.USERNAME,s.SALARY,s.MONTH FROM LoginInfo l  INNER JOIN SalaryInfo s ON l.ROWID==s.USERID WHERE 1=1";
	        	
	        	if(Username.length()!=0)
	        	{
	        		WHERE=WHERE+" "+"AND"+" "+"l.USERNAME"+" "+"LIKE"+" '"+Username+"%'";
	        	
	        		//WHERE=WHERE+" "+"AND"+" "+"LoginInfo.USERNAME="+Username+"%";
	        	
	        	}
	        	else
	        	{
	        		
	        	}
	        	if(Month.length()!=0)
	        	{
	        		WHERE=WHERE+" "+"AND"+" "+"s.MONTH"+" "+"LIKE"+" '"+Month+"%'";
	        	
	        		//WHERE=WHERE+" "+"AND"+" "+"SalaryInfo.MONTH="+Month+"%";
	        	
	        	}
	        	else
	        	{
	        		
	        	}
	        	if(fromsalary.length()!=0&&tosalary.length()!=0)
	        	{
	        		WHERE=WHERE+" "+"AND"+" "+"s.SALARY"+" "+"BETWEEN"+" "+fromsalary+" "+"AND"+" "+tosalary;
	        	}
	        	else if(fromsalary.length()!=0)
	        	{
	        		WHERE=WHERE+" "+"AND"+" "+"s.SALARY="+fromsalary;
	        	}
	        	else if(tosalary.length()!=0)
	        		
	        	{
	        		WHERE=WHERE+" "+"AND"+" "+"s.SALARY="+tosalary;
	        	}
	        	else
	        	{
	        		
	        	}
	        	query=query+WHERE;
	        	
	        	System.out.println("query=-===>"+query);
	        	
	        	 c1=db.rawQuery(query,null);
	        	
	        
	        	
	        	
	        	
	        	
	    //  Cursor c1=db.rawQuery("SELECT LoginInfo.USERNAME,SalaryInfo.SALARY,SalaryInfo.MONTH from LoginInfo INNER JOIN SalaryInfo ON LoginInfo.ROWID==SalaryInfo.USERID WHERE LoginInfo.USERNAME LIKE '"+Username+"%' AND SalaryInfo.MONTH LIKE '"+Month+"%' AND (SalaryInfo.SALARY BETWEEN '"+fromsalary+"' AND '"+tosalary+"')" , null);
	        	//Cursor c1=db.rawQuery("SELECT LoginInfo.USERNAME,SalaryInfo.SALARY,SalaryInfo.MONTH from LoginInfo INNER JOIN SalaryInfo WHERE LoginInfo.ROWID==SalaryInfo.USERID AND LoginInfo.USERNAME LIKE '"+Username+"%' AND SalaryInfo.MONTH LIKE '"+Month+"%' AND SalaryInfo.SALARY>='"+fromsalary+"' AND SalaryInfo.SALARY<='"+tosalary+"'" , null);
	        	
	        	if(c1!=null)
	    		{
	    		 
	    		if(c1.moveToFirst())
	    		{
	    			
	    			do
	    			{
	    				Model1 m1=new Model1();
	    			 String	 salary=c1.getString(1);
	    			 String	 month=c1.getString(2);
	    			 String	 name=c1.getString(0);
	    			
	    				 System.out.println("hi values"+"\t"+salary+"\t"+month+"\t"+name);
	    				// b1=BitmapFactory.decodeByteArray(img1, 0, img1.length);
	    				 
	    				 m1.setName(name);
	    				 m1.setSalary(salary);
	    				 m1.setMonth(month);
	    				
	    				 
	    				l1.add(m1);
	    			
	    				} while (c1.moveToNext());
	    			
	    			
	    		}
	    		}
	    		
	        	c1.close();
	    for (int i = 0; i < l1.size(); i++) {
	    			
	    			System.out.println("DATAA===>"+l1.get(i).getSalary()+""+l1.get(i).getMonth());
	    		}
	    salaryListAdapter = new SalaryListAdapter(ViewPage1.this, l1);
	   list.setAdapter(salaryListAdapter);
	    salaryListAdapter.notifyDataSetChanged();
	        	
	      
	           }
	        });

	        alert.setNegativeButton("Cancel", new DialogInterface.OnClickListener() 
	        {
	          public void onClick(DialogInterface dialog, int whichButton) 
	          {
	            // Canceled.
	          }
	        });

	        alert.show();
			
		}
	});
		
	}

}
