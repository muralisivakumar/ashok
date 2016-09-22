package com.example.administrator.databaseregistrationapp;

import android.app.Fragment;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.Gallery;
import android.widget.ImageView;
import android.widget.Toast;

public class Fragment5 extends Fragment
{
	
	private Gallery gallery;

    private ImageView selectedImage;
    


    private Integer[] mImageIds = {   R.drawable.baby1,
            R.drawable.baby1,
            R.drawable.baby1,
            R.drawable.baby1,
            R.drawable.baby1,
            R.drawable.baby1

            };
    
public Fragment5(){}
	
	@Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,Bundle savedInstanceState) 
	{
		//This method having the Benefits data
		//BenefitsData();
        View rootView = inflater.inflate(R.layout.activity_gallery_main, container, false);
        
        Gallery gallery = (Gallery)rootView.findViewById(R.id.gallery1);
        selectedImage=(ImageView)rootView.findViewById(R.id.imageView1);
        gallery.setSpacing(1);
        AddImgAdp adp=new AddImgAdp(getActivity());
        gallery.setAdapter(adp);

         // clicklistener for Gallery
        gallery.setOnItemClickListener(new OnItemClickListener() {
            public void onItemClick(AdapterView<?> parent, View v, int position, long id) 
            {
                Toast.makeText(getActivity(), "Your selected position = " + position, Toast.LENGTH_SHORT).show();
                // show the selected Image
                selectedImage.setImageResource(mImageIds[position]);
            }
        });
        return rootView;
}
}
