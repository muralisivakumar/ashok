package com.example.administrator.databaseregistrationapp;

import java.io.ByteArrayOutputStream;


import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.Toast;

public class RegistrationPage extends Activity 
{
	
	EditText firstname,email,password,phonenumber;
	ImageView image;
	byte[] img;
	SharedPreferences sh_Pref;
	SharedPreferences.Editor toEdit;

	Bitmap b;


	    
	Button homepage,submit,reset;
private DatabaseHelper database;

	@Override
	protected void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_registration_page);

		firstname=(EditText)findViewById(R.id.firstName);
		email=(EditText)findViewById(R.id.eMail);
		password=(EditText)findViewById(R.id.password);
		phonenumber=(EditText)findViewById(R.id.phone);
		homepage=(Button)findViewById(R.id.home);
		submit=(Button)findViewById(R.id.submit);
		reset=(Button)findViewById(R.id.reset);
		image=(ImageView)findViewById(R.id.image);
		database=new DatabaseHelper(this);
		sh_Pref = getSharedPreferences("login credentials", MODE_PRIVATE);
		toEdit = sh_Pref.edit();
		
		toEdit.putString("Username","admin@admin.com");
		toEdit.commit();
		
		homepage.setOnClickListener(new OnClickListener()
		{
			
			@Override
			public void onClick(View arg0) 
			{
				// TODO Auto-generated method stub
				Intent homepage=new Intent(RegistrationPage.this,MainActivity.class);
				startActivity(homepage);
			}
		});
		submit.setOnClickListener(new OnClickListener() 
		{
			
			@Override
			public void onClick(View v) 
			{
				// TODO Auto-generated method stub
				
				    String firstName = firstname.getText().toString();
				    String eMail= email.getText().toString();
				    String passWord=password.getText().toString();
				    String phone=phonenumber.getText().toString();
				    b=BitmapFactory.decodeResource(getResources(), R.drawable.ic_launcher);
				    ByteArrayOutputStream bos=new ByteArrayOutputStream();
				    b.compress(Bitmap.CompressFormat.PNG, 100, bos);
                    img=bos.toByteArray();
				    
				    if(firstName.length()>0&&eMail.length()>0&&password.length()>0&&phone.length()>0)
				    {
				    
				    database.InsertValues(firstName, eMail, passWord, phone,img);
				Intent loginpage=new Intent(RegistrationPage.this,LoginWebPage.class);
				Toast.makeText(getApplicationContext(), "Registered Successfully", Toast.LENGTH_SHORT).show();
				startActivity(loginpage);
				    }
				    else 
				    {
				    	Toast.makeText(getApplicationContext(), "please enter valid values", Toast.LENGTH_SHORT).show();
				    	
				    }
				   
				
				
			}
		});
		reset.setOnClickListener(new OnClickListener() 
		{
			
			@Override
			public void onClick(View v) 
			{
				// TODO Auto-generated method stub
				
	firstname.setText("");
	email.setText("");
	password.setText("");
	phonenumber.setText("");
				
				
			}
		});
	}
	
	

}
