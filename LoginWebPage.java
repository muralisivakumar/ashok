package com.example.administrator.databaseregistrationapp;



import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;

public class LoginWebPage extends Activity 
{
  EditText email,password;
  Button homepage,submit,reset;
  DatabaseHelper database;
  SQLiteDatabase db ;
  String mail,pwd,adminmail;
  SharedPreferences sh_Pref;


 
	@Override
	protected void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_login_web_page);
		email=(EditText)findViewById(R.id.eMail);
		password=(EditText)findViewById(R.id.password);
		homepage=(Button)findViewById(R.id.homepage);
		submit=(Button)findViewById(R.id.submit);
		reset=(Button)findViewById(R.id.reset);
		database=new DatabaseHelper(this);
		database.getWritableDatabase();
		mail= email.getText().toString();
		sh_Pref=getSharedPreferences("login credentials", MODE_PRIVATE);
       adminmail=sh_Pref.getString("Username","");
		
		homepage.setOnClickListener(new OnClickListener() 
		{
			
			@Override
			public void onClick(View arg0) 
			{
				// TODO Auto-generated method stub
				
			Intent homepage=new Intent(LoginWebPage.this,MainActivity.class);
			
			startActivity(homepage);
			
			}
		});
		
		submit.setOnClickListener(new OnClickListener() 
		{
			
			@Override
			public void onClick(View v) 
			{
				// TODO Auto-generated method stub
				mail= email.getText().toString();
				if(adminmail.equalsIgnoreCase(mail))
				{
					Intent adminpage=new Intent(LoginWebPage.this,AdminUsersSalaries.class);
					
					startActivity(adminpage);
				}
				else
				{
				Intent displaydetais=new Intent(LoginWebPage.this,DispalyDetails.class);
				
				displaydetais.putExtra("EMAIL",mail);
	
				startActivity(displaydetais);
				}
				
			}
		});
       reset.setOnClickListener(new OnClickListener() 
       {
		
		@Override
		public void onClick(View arg0) 
		{
			// TODO Auto-generated method stub
			email.setText("");
			password.setText("");
			
		}
	});
		
	}


	
		
	
	

}
