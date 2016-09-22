package com.example.administrator.databaseregistrationapp;



import android.app.Activity;
import android.content.Intent;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;

public class ProductInfo extends Activity 
{
   EditText name,date;
   Button HomePage,submit,reset;
   DatabaseHelper db;
   SQLiteDatabase database;
   String Name,Purchasedate;
   String UserId;
 
	
	//Cursor c;
	@Override
	protected void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_product_info);

		name=(EditText)findViewById(R.id.productname);
		date=(EditText)findViewById(R.id.purchasedate);
		HomePage=(Button)findViewById(R.id.home);
		submit=(Button)findViewById(R.id.submit);
		reset=(Button)findViewById(R.id.reset);
		
		db=new DatabaseHelper(this);
		
		submit.setOnClickListener(new OnClickListener() 
		{
			
			@Override
			public void onClick(View arg0) 
			{
				// TODO Auto-generated method stub
				Name=name.getText().toString();
				Purchasedate=date.getText().toString();
				
				
			db.insertProductDetails(Name,Purchasedate);
			Intent addressinfo=new Intent(ProductInfo.this,AddressInfo.class);
			startActivity(addressinfo);
			}
		});
		
		
		reset.setOnClickListener(new OnClickListener() 
		{
			
			@Override
			public void onClick(View v) 
			{
				// TODO Auto-generated method stub

				name.setText("");
				date.setText("");
				
			}
		});
		
		HomePage.setOnClickListener(new OnClickListener() 
		{
			
			@Override
			public void onClick(View v) 
			{
				// TODO Auto-generated method stub
				Intent homepage=new Intent(ProductInfo.this,MainActivity.class);
				startActivity(homepage);
			}
		});
		

	}

}
