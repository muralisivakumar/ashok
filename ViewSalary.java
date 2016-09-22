package com.example.administrator.databaseregistrationapp;



import android.app.Activity;
import android.app.AlertDialog;
import android.content.ContentValues;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

public class ViewSalary extends Activity 
{
   TextView Empsalary,EmpMonth,EmpYear;
   Button addsalary,editsalary,editmonth,edityear,savesalary,homepage;
   DatabaseHelper database;
   SQLiteDatabase db;
   String salary,month,year;
   String newSalary,newMonth,newYear,NewSalary,NewMonth,NewYear;
   final Context context=this;
   
	@Override
	protected void onCreate(Bundle savedInstanceState)
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_view_salary);
		Empsalary=(TextView)findViewById(R.id.text1);
		EmpMonth=(TextView)findViewById(R.id.text2);
		EmpYear=(TextView)findViewById(R.id.text3);
		
		
		addsalary=(Button)findViewById(R.id.addnewsalary);
		editsalary=(Button)findViewById(R.id.edit);
		editmonth=(Button)findViewById(R.id.editMonth);
		edityear=(Button)findViewById(R.id.editYear);
		savesalary=(Button)findViewById(R.id.Save);
		homepage=(Button)findViewById(R.id.homePage);
		
		database=new DatabaseHelper(this);
		db=database.getReadableDatabase();
		db=database.getWritableDatabase();
		
		

 Cursor c = db.rawQuery("SELECT SALARY,MONTH,JOINEDDATE from SalaryInfo", null);   
		 
		 if(c!=null)
		 {
		 
		if(c.moveToFirst())
		{
			
			do 
			{
				
				//Toast.makeText(getApplicationContext(), ""+c.getString(0), Toast.LENGTH_SHORT).show();
				salary=c.getString(0);
				month=c.getString(1);
				year=c.getString(2);
            //  l1.add(object);
				
				Empsalary.setText(salary);
				EmpMonth.setText(month);
				EmpYear.setText(year);
            
			} while (c.moveToNext());
		}
		 }
		 
		 
		 
		addsalary.setOnClickListener(new OnClickListener() 
		 {
			
			@Override
			public void onClick(View arg0) 
			{
				// TODO Auto-generated method stub
				editsalary.setOnClickListener(new OnClickListener() 
				{
					
					@Override
					public void onClick(View v) 
					{
						
						// TODO Auto-generated method stub
						
						Empsalary.setOnClickListener(new OnClickListener() 
						{
							
							@Override
							public void onClick(View arg0) 
							{
								// TODO Auto-generated method stub
								
								
								AlertDialog.Builder alert = new AlertDialog.Builder(context);
					            alert.setTitle("Alert Dialog With EditText"); //Set Alert dialog title here
					            alert.setMessage("Enter Your Name Salary Here"); //Message here
					 
					            // Set an EditText view to get user input 
					            final EditText input = new EditText(context);
					            alert.setView(input);
					 
					            alert.setPositiveButton("OK", new DialogInterface.OnClickListener() 
					            {
					            public void onClick(DialogInterface dialog, int whichButton) 
					            {
					             //You will get as string input data in this variable.
					             // here we convert the input to a string and show in a toast.
					            newSalary = input.getEditableText().toString();
					           Empsalary.setText(newSalary);
					            
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
						}); //End Of EmpSalary Listener
									
							}
						});  //End Of editsalary Listeners
				
				
				
				editmonth.setOnClickListener(new OnClickListener() 
				{
					
					@Override
					public void onClick(View v) 
					{
						
						// TODO Auto-generated method stub
						
						EmpMonth.setOnClickListener(new OnClickListener() 
						{
							
							@Override
							public void onClick(View arg0) 
							{
								// TODO Auto-generated method stub
								
								
								AlertDialog.Builder alert = new AlertDialog.Builder(context);
					            alert.setTitle("Alert Dialog With EditText"); //Set Alert dialog title here
					            alert.setMessage("Enter Your Updated Month Here"); //Message here
					 
					            // Set an EditText view to get user input 
					            final EditText input = new EditText(context);
					            alert.setView(input);
					 
					            alert.setPositiveButton("OK", new DialogInterface.OnClickListener() 
					            {
					            public void onClick(DialogInterface dialog, int whichButton) 
					            {
					             //You will get as string input data in this variable.
					             // here we convert the input to a string and show in a toast.
					            newMonth = input.getEditableText().toString();
					          EmpMonth.setText(newMonth);
					            
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
						});//End Of EmpMonth listeners
								
								
								}
						}); //End of editmonth listeners
				
				
				
				edityear.setOnClickListener(new OnClickListener() 
				{
					
					@Override
					public void onClick(View v) 
					{
						
						// TODO Auto-generated method stub
						
						EmpYear.setOnClickListener(new OnClickListener() 
						{
							
							@Override
							public void onClick(View arg0) 
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
					            newSalary = input.getEditableText().toString();
					          EmpYear.setText(newSalary);
					            
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
						});//End Of EmpYear clicklistener
								
									
							}
						});//End Of Edityear listener
				
				
				NewSalary=Empsalary.getText().toString();
				NewMonth=EmpMonth.getText().toString();
				NewYear=EmpYear.getText().toString();
				
					
			}
			}); //End Of AddSalary Listener
		
		
		savesalary.setOnClickListener(new OnClickListener() 
		{
			
			@Override
			public void onClick(View v) 
			{
				// TODO Auto-generated method stub
				updateSalary(NewSalary,NewMonth,NewYear);
			}

		});
					
		 
		 homepage.setOnClickListener(new OnClickListener() 
		 {
			
			@Override
			public void onClick(View arg0) 
			{
				// TODO Auto-generated method stub
				
				Intent homepage=new Intent(ViewSalary.this,MainActivity.class);
				startActivity(homepage);
				
				
			}
		});
		 

	}
	
	
	public boolean updateSalary(String newSalary,String newMonth,String newYear)
	{
		db=database.getWritableDatabase();
		ContentValues contentValues = new ContentValues();
	      contentValues.put("SALARY", newSalary);
	      contentValues.put("MONTH", newMonth);
	      contentValues.put("JOINEDDATE", newYear);
	      System.out.println("updated values are:"+"\t"+newSalary+"\t"+newMonth+"\t"+newYear);
	      db.update("SalaryInfo", contentValues, "JOINEDDATE = ? ", new String[] {newYear} );
	      return true;
		
	}
	 }

		
