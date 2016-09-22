package com.example.administrator.databaseregistrationapp;



import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemSelectedListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.Toast;

public class AddressInfo extends Activity 
{

	Spinner adressinfo;
	Button addnewaddress,submit,reset,homepage,activityinfo;
	EditText pid,street,shipdate,addressid;
	
	String AddressId,Pid,Street,ShipDate;
	
	DatabaseHelper db;
	SQLiteDatabase database;

	  String UserID;
	  SharedPreferences sh_Pref;
	
	
	@Override
	protected void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_address_info);

	pid=(EditText)findViewById(R.id.productid);
	addressid=(EditText)findViewById(R.id.addressid);
	shipdate=(EditText)findViewById(R.id.shippingdate);
	
	adressinfo=(Spinner)findViewById(R.id.addexistingaddress);
	
	addnewaddress=(Button)findViewById(R.id.addnewaddress);
	submit=(Button)findViewById(R.id.submit);
	reset=(Button)findViewById(R.id.reset);
	homepage=(Button)findViewById(R.id.home);
	activityinfo=(Button)findViewById(R.id.activityinfo);
	
	
	
	
	db=new DatabaseHelper(this);
	database=db.getReadableDatabase();
	database=db.getWritableDatabase();
	
	
	
	
	
	homepage.setOnClickListener(new OnClickListener() 
	{
		
		@Override
		public void onClick(View arg0)
		{
			// TODO Auto-generated method stub
		     Intent home=new Intent(AddressInfo.this,MainActivity.class);
		     startActivity(home);
		}
	});
	reset.setOnClickListener(new OnClickListener() 
	{
		
		@Override
		public void onClick(View v) 
		{
			// TODO Auto-generated method stub
			pid.setText("");
			street.setText("");
			shipdate.setText("");
		}
	});
	activityinfo.setOnClickListener(new OnClickListener() 
	{
		
		@Override
		public void onClick(View arg0)
         {
			// TODO Auto-generated method stub
			Intent activityinfo=new Intent(AddressInfo.this,ActivityInfo.class);
			startActivity(activityinfo);
		}
	});
	
	addnewaddress.setOnClickListener(new OnClickListener() 
	{
		
		@Override
		public void onClick(View v) 
		{
			// TODO Auto-generated method stub
		
			street.setText("");
			
			street=(EditText)findViewById(R.id.street);			
			
			
		}
	});
	
	
	adressinfo.setOnItemSelectedListener(new OnItemSelectedListener() 
	{

		@Override
		public void onItemSelected(AdapterView<?> arg0, View arg1, int pos,long arg3) 
		{
			// TODO Auto-generated method stub
	
			String address=adressinfo.getItemAtPosition(pos).toString();
			street=(EditText)findViewById(R.id.street);	
			street.setText(address);
			
		}

		@Override
		public void onNothingSelected(AdapterView<?> arg0) 
		{
			// TODO Auto-generated method stub
			
		}
	});
	
	submit.setOnClickListener(new OnClickListener() 
	{
		
		@Override
		public void onClick(View arg0) 
		{
			// TODO Auto-generated method stub
			
			Pid=pid.getText().toString();
			Street=street.getText().toString();
			ShipDate=shipdate.getText().toString();
			AddressId=addressid.getText().toString();
			
			db.insertAdressDetails(Pid,AddressId,Street,ShipDate);
			sh_Pref=getSharedPreferences("SharedPrefer UserId", MODE_PRIVATE);
			   UserID=sh_Pref.getString("USERID","");
			System.out.println("User id is\t"+UserID);
			
			Toast.makeText(AddressInfo.this,"Inserted Values Succeessfully",Toast.LENGTH_SHORT).show();
			db.insertActivityDetails(UserID,Pid,AddressId,ShipDate);
		}
	});
	
	
	
	}

}
