package com.example.administrator.databaseregistrationapp;

import java.util.ArrayList;



import android.app.Activity;
import android.app.AlertDialog;
import android.content.ContentValues;
import android.content.Context;
import android.content.DialogInterface;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;

public class DisplayDetailsOne extends Activity 
{
    LoginWebPage loginpage;
	String email,name,mail,phonenumber,Salary,Month,Year;
	SQLiteDatabase db;
	TextView fname,cmail,phone,salary,month,year;
	ImageView image;
	ArrayList<Model> l1;
	byte[] img1;
	Bitmap b1;
	int pos;
	Button edit;
	Button save;
	final Context context=this;
	 String newname,newemail,newphone;
	 String newName,newEmail,newPhone;
	 DatabaseHelper database=new DatabaseHelper(this);
	
	ArrayList<String> list=new ArrayList<String>();
	
	@Override
	protected void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_display_details_one);
		loginpage=new LoginWebPage();
		
		db=database.getWritableDatabase();
		db=database.getReadableDatabase();

	   fname=(TextView)findViewById(R.id.text1);
	   cmail=(TextView)findViewById(R.id.text2);
	  phone=(TextView)findViewById(R.id.text3);
	  salary=(TextView)findViewById(R.id.text4);
	  month=(TextView)findViewById(R.id.text5);
	  year=(TextView)findViewById(R.id.text6);
	  
	  
	  
	  image=(ImageView)findViewById(R.id.image);
	  
	  edit=(Button)findViewById(R.id.edit);
	  save=(Button)findViewById(R.id.save);
	   

		pos=getIntent().getExtras().getInt("Position");
		pos=pos+1;
	
		Cursor c1= db.rawQuery("SELECT LoginInfo.IMAGE,LoginInfo.USERNAME,LoginInfo.EMAIL,LoginInfo.MOBILE,SalaryInfo.SALARY,SalaryInfo.MONTH,SalaryInfo.JOINEDDATE from LoginInfo LEFT OUTER JOIN SalaryInfo WHERE ROWID = '"+pos+"' and LoginInfo.ROWID==SalaryInfo.USERID", null);   
		 
		 if(c1!=null)
		 {
		 
		if(c1.moveToFirst())
		{
			
			do {
				
				//Toast.makeText(getApplicationContext(), ""+c.getString(0), Toast.LENGTH_SHORT).show();
				 name=c1.getString(1);
				 mail=c1.getString(2);
				 phonenumber=c1.getString(3);
				 img1=c1.getBlob(0);
				 Salary=c1.getString(4);
				 Month=c1.getString(5);
				 Year=c1.getString(6);
				 
				 b1=BitmapFactory.decodeByteArray(img1, 0, img1.length);
	                image.setImageBitmap(b1);
				fname.setText(name);
               cmail.setText(mail);
               phone.setText(phonenumber);
               salary.setText(Salary);
               month.setText(Month);
               year.setText(Year);
           //  l1.add(object);
           
			} while (c1.moveToNext());
		}
		 }
		 
		 
		 
		 
		 
		 edit.setOnClickListener(new OnClickListener() 
		 {
			
			@Override
			public void onClick(View arg0) 
			{
				// TODO Auto-generated method stub
				fname.setOnClickListener(new OnClickListener() 
				{
					
					@Override
					public void onClick(View v) 
					{
						// TODO Auto-generated method stub
						AlertDialog.Builder alert = new AlertDialog.Builder(context);
			            alert.setTitle("Alert Dialog With EditText"); //Set Alert dialog title here
			            alert.setMessage("Enter Your Name Here"); //Message here
			 
			            // Set an EditText view to get user input 
			            final EditText input = new EditText(context);
			            alert.setView(input);
			 
			            alert.setPositiveButton("OK", new DialogInterface.OnClickListener() 
			            {
			            public void onClick(DialogInterface dialog, int whichButton) 
			            {
			             //You will get as string input data in this variable.
			             // here we convert the input to a string and show in a toast.
			            newname = input.getEditableText().toString();
			            fname.setText(newname);
			       
			            // Toast.makeText(context,srt,Toast.LENGTH_LONG).show();                
			            } // End of onClick(DialogInterface dialog, int whichButton)
			        }); //End of alert.setPositiveButton
			            alert.setNegativeButton("CANCEL", new DialogInterface.OnClickListener() 
			            {
			              public void onClick(DialogInterface dialog, int whichButton) 
			              {
			                // Canceled.
			                  dialog.cancel();
			              }
			        }); //End of alert.setNegativeButton
			            
			            AlertDialog alertDialog = alert.create();
			            alertDialog.show();
			            
					}
				});
				
				cmail.setOnClickListener(new OnClickListener() 
				{
					
					@Override
					public void onClick(View arg0) 
					{
						// TODO Auto-generated method stub
						AlertDialog.Builder alert = new AlertDialog.Builder(context);
			            alert.setTitle("Alert Dialog With EditText"); //Set Alert dialog title here
			            alert.setMessage("Enter Your mail Here"); //Message here
			 
			            // Set an EditText view to get user input 
			            final EditText input1 = new EditText(context);
			            alert.setView(input1);
			 
			            alert.setPositiveButton("OK", new DialogInterface.OnClickListener() 
			            {
			            public void onClick(DialogInterface dialog, int whichButton) 
			            {
			             //You will get as string input data in this variable.
			             // here we convert the input to a string and show in a toast.
			            newemail = input1.getEditableText().toString();
			            cmail.setText(newemail);
			   
			            // Toast.makeText(context,srt,Toast.LENGTH_LONG).show();                
			            } // End of onClick(DialogInterface dialog, int whichButton)
			        }); //End of alert.setPositiveButton
			            alert.setNegativeButton("CANCEL", new DialogInterface.OnClickListener() 
			            {
			              public void onClick(DialogInterface dialog, int whichButton) 
			              {
			                // Canceled.
			                  dialog.cancel();
			              }
			        }); //End of alert.setNegativeButton
			            
			            AlertDialog alertDialog = alert.create();
			            alertDialog.show();
			            
					}
				});
				
				phone.setOnClickListener(new OnClickListener() 
				{
					
					@Override
					public void onClick(View arg0) 
					{
						// TODO Auto-generated method stub
						AlertDialog.Builder alert = new AlertDialog.Builder(context);
			            alert.setTitle("Alert Dialog With EditText"); //Set Alert dialog title here
			            alert.setMessage("Enter Your Mobile Number Here"); //Message here
			 
			            // Set an EditText view to get user input 
			            final EditText input1 = new EditText(context);
			            alert.setView(input1);
			 
			            alert.setPositiveButton("OK", new DialogInterface.OnClickListener() 
			            {
			            public void onClick(DialogInterface dialog, int whichButton) 
			            {
			             //You will get as string input data in this variable.
			             // here we convert the input to a string and show in a toast.
			            newphone = input1.getEditableText().toString();
			           phone.setText(newphone);
			
			            // Toast.makeText(context,srt,Toast.LENGTH_LONG).show();                
			            } // End of onClick(DialogInterface dialog, int whichButton)
			        }); //End of alert.setPositiveButton
			            alert.setNegativeButton("CANCEL", new DialogInterface.OnClickListener() 
			            {
			              public void onClick(DialogInterface dialog, int whichButton) 
			              {
			                // Canceled.
			                  dialog.cancel();
			              }
			        }); //End of alert.setNegativeButton
			            
			            AlertDialog alertDialog = alert.create();
			            alertDialog.show();
			          
			            
					}
				});
			     newName=fname.getText().toString();
		           newPhone=phone.getText().toString();
		         newEmail=cmail.getText().toString();
				 
			}
		});
		 save.setOnClickListener(new OnClickListener() 
		 {
			
			@Override
			public void onClick(View arg0) 
			{
				// TODO Auto-generated method stub
				
				  updateContact(newName, newEmail, newPhone);
				
			}
		});
		
}
	public boolean updateContact (String name,String mail,String phone)
	   {
	     db = database.getWritableDatabase();
	      ContentValues contentValues = new ContentValues();
	      contentValues.put("USERNAME", name);
	      contentValues.put("EMAIL", mail);
	      contentValues.put("MOBILE", phone);
	      System.out.println("updated values are:"+"\t"+name+"\t"+mail+"\t"+phone);
	      db.update("LoginInfo", contentValues, "USERNAME = ? ", new String[] {name} );
	      return true;
	   }

}
