package com.example.administrator.databaseregistrationapp;

;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemSelectedListener;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.Toast;

public class SalaryPage extends Activity 
{
    EditText salary,userid;;
    Spinner month,year;
    Button Submit,Reset,viewSalary,viewproduct;
    DatabaseHelper db;
    String Salary,Month,Year;
    String UserID;
	 ArrayAdapter<CharSequence> adapter,adapter1;
	 SQLiteDatabase database;
	 SharedPreferences sh_Pref;
		SharedPreferences.Editor toEdit;
	
	@Override
	protected void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_salary_page);
		  db=new DatabaseHelper(this);
		  database=db.getReadableDatabase();
		  database=db.getWritableDatabase();
		
		userid=(EditText)findViewById(R.id.userid);  
		salary=(EditText)findViewById(R.id.salary);
		month=(Spinner)findViewById(R.id.month);
		year=(Spinner)findViewById(R.id.joineddate);
		Submit=(Button)findViewById(R.id.submit);
		Reset=(Button)findViewById(R.id.Reset);
		viewSalary=(Button)findViewById(R.id.viewSalaryDetails);
		viewproduct=(Button)findViewById(R.id.viewProductDetails);

		
		
      
        
  /*      
        adapter = ArrayAdapter.createFromResource(this,R.array.month,android.R.layout.simple_spinner_item);
         
         adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
         
       month.setAdapter(adapter);*/
      month.setOnItemSelectedListener(new OnItemSelectedListener() 
      {

		@Override
		public void onItemSelected(AdapterView<?> arg0, View arg1, int pos,
				long arg3) 
		{
			// TODO Auto-generated method stub
			Month=month.getItemAtPosition(pos).toString();
			Toast.makeText(getApplicationContext(), "selected"+Month, Toast.LENGTH_SHORT).show();
		}

		@Override
		public void onNothingSelected(AdapterView<?> arg0) 
		{
			// TODO Auto-generated method stub
			Toast.makeText(getApplicationContext(), "please select one value", Toast.LENGTH_SHORT).show();
			
		}
	});
         
      /*adapter1 = ArrayAdapter.createFromResource(this,R.array.year,android.R.layout.simple_spinner_item);
      
      adapter1.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
      
    year.setAdapter(adapter1);*/
  year.setOnItemSelectedListener(new OnItemSelectedListener() 
   {

		@Override
		public void onItemSelected(AdapterView<?> arg0, View arg1, int pos,
				long arg3) 
		{
			// TODO Auto-generated method stub
			 Year=year.getItemAtPosition(pos).toString();
			Toast.makeText(getApplicationContext(), "selected"+Year, Toast.LENGTH_SHORT).show();
		}

		@Override
		public void onNothingSelected(AdapterView<?> arg0) 
		{
			// TODO Auto-generated method stub
			Toast.makeText(getApplicationContext(), "please select one value", Toast.LENGTH_SHORT).show();
			
		}
	});
      Submit.setOnClickListener(new OnClickListener() 
      {
		
		@Override
		public void onClick(View arg0) 
		{
			// TODO Auto-generated method stub
			
		
			
			UserID=userid.getText().toString();
			
			sh_Pref = getSharedPreferences("SharedPrefer UserId", MODE_PRIVATE);
			toEdit = sh_Pref.edit();
			
			toEdit.putString("USERID",UserID);
			toEdit.commit();
			
			
			
			System.out.println("UserId is\t"+UserID);
			
			
	    

			Salary=salary.getText().toString();
			db.insertSalaryDetails(UserID,Month,Salary,Year);
			
			
			Intent products=new Intent(SalaryPage.this,ProductInfo.class);
			System.out.println("ProductInfo Userid is:"+UserID);
			products.putExtra("USERID", UserID);
			
			startActivity(products);
			
		}
	});
      Reset.setOnClickListener(new OnClickListener() 
      {
		
		@Override
		public void onClick(View arg0) 
		{
			// TODO Auto-generated method stub
			
			
		}
	});
     viewSalary.setOnClickListener(new OnClickListener() 
      {
		
		@Override
		public void onClick(View v) 
		{
			// TODO Auto-generated method stub
			Intent viewpage=new Intent(SalaryPage.this,ViewSalary.class);
			startActivity(viewpage);
			
		}
	});
     
     viewproduct.setOnClickListener(new OnClickListener() 
     {
		
		@Override
		public void onClick(View arg0) 
		{
			// TODO Auto-generated method stub
			UserID=userid.getText().toString();
			
			System.out.println("UserId is\t"+UserID);
		
			
Intent productaddress=new Intent(SalaryPage.this,ViewProductAddress.class);
    productaddress.putExtra("USERID", UserID);
			
			startActivity(productaddress);
		}
	});
        
	}
}
         
       